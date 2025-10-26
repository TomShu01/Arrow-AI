"""
Supervisor Agent - Main workflow orchestrator
Routes requests through complexity analysis → planning → execution
"""

from Arrow_AI_Backend.agent.agents.complexity_analyzer import complexity_analyzer
from Arrow_AI_Backend.agent.agents.executor import agent_executor
from Arrow_AI_Backend.agent.agents.planner import planner
from Arrow_AI_Backend.agent.states import PlanExecute
from langgraph.graph import StateGraph, START, END
from Arrow_AI_Backend.manager import manager


# ========== Step 1: Analyze Complexity ==========
async def analyze_complexity(state: PlanExecute):
    """Determine if the query is SIMPLE or COMPLEX"""
    result = await complexity_analyzer.ainvoke({"input": state["input"]})
    print(f"[Complexity] {result.complexity} - {result.reasoning}")
    return {"complexity": result.complexity}


# ========== Step 2: Notify User ==========
async def notify_user(state: PlanExecute):
    """Send user-friendly message based on complexity"""
    if state["complexity"] == "COMPLEX":
        message = "I'm creating a plan for your request..."
    else:
        message = "Working on it..."
    
    await manager.send(state["session_id"], {
        "type": "chat_response",
        "message": message
    })
    return {}


# ========== Step 3: Create Plan ==========
async def plan_step(state: PlanExecute):
    """Create plan for complex queries, or simple single-task plan for simple queries"""
    # Check if we're replanning
    if state.get("replan_reason"):
        # Replanning requested by decider
        replan_context = f"{state['input']}\n\nReplanning because: {state['replan_reason']}\n\nCompleted steps: {state.get('past_steps', [])}"
        plan = await planner.ainvoke({"messages": [("user", replan_context)]})
        steps = plan.steps
        
        # Send new plan to user
        plan_text = "\n".join(f"{i+1}. {step}" for i, step in enumerate(steps))
        await manager.send(state["session_id"], {
            "type": "chat_response",
            "message": f"I've updated the plan:\n{plan_text}"
        })
        return {"plan": steps, "replan_reason": ""}  # Reset completed tasks and clear replan_reason
    
    elif state["complexity"] == "COMPLEX":
        # Initial planning for complex queries
        plan = await planner.ainvoke({"messages": [("user", state["input"])]})
        steps = plan.steps
        
        # Send plan to user
        plan_text = "\n".join(f"{i+1}. {step}" for i, step in enumerate(steps))
        await manager.send(state["session_id"], {
            "type": "chat_response",
            "message": f"Here's my plan:\n{plan_text}"
        })
    else:
        # Simple query: create a single-task plan
        steps = [state["input"]]
    
    return {"plan": steps}


# ========== Step 4: Execute Task ==========
async def execute_step(state: PlanExecute):
    """Execute the current task using the executor agent with tools"""
    from Arrow_AI_Backend.agent.tools.arrow_tools import set_context
    
    plan = state["plan"]
    
    # Set context for tools (session_id, scene_id, and arrow_file)
    set_context(
        session_id=state["session_id"],
        scene_id=state.get("current_scene_id"),
        arrow_file=state.get("arrow_file")
    )
    
    # Give the executor ALL remaining tasks
    # The executor agent has its own internal loop and will work through them
    plan_text = "\n".join(f"{i+1}. {step}" for i, step in enumerate(plan))
    
    execution_prompt = f"""Complete the following plan step-by-step:

{plan_text}

IMPORTANT: Work through these steps IN ORDER. After completing each step with a tool, verify the result before moving to the next step. Do not skip steps or execute them out of order."""
    
    print(f"[Supervisor] Sending {len(plan)} tasks to executor")
    print(f"[Supervisor] Plan:\n{plan_text}")
    
    # Invoke the executor agent
    # The agent has its own internal loop and will work through all tasks
    try:
        result = await agent_executor.ainvoke(
            {"messages": [{"role": "user", "content": execution_prompt}]},
            config={"recursion_limit": 100}
        )
        
        # Extract the final response from the agent
        messages = result.get("messages", [])
        final_message = messages[-1] if messages else None
        response_text = final_message.content if final_message else "Tasks executed"
        
        # Notify user
        await manager.send(state["session_id"], {
            "type": "chat_response",
            "message": response_text
        })
        
        # Mark the first task as complete
        task = plan[0]
        return {
            "past_steps": [(task, response_text)],
        }
        
    except Exception as e:
        error_msg = f"Error executing tasks: {str(e)}"
        await manager.send(state["session_id"], {
            "type": "chat_response",
            "message": error_msg
        })
        return {
            "past_steps": [(plan[0], error_msg)],
        }


# ========== Build Workflow ==========
workflow = StateGraph(PlanExecute)

workflow.add_node("analyze", analyze_complexity)
workflow.add_node("notify_user", notify_user)
workflow.add_node("plan", plan_step)
workflow.add_node("execute", execute_step)

workflow.add_edge(START, "analyze")
workflow.add_edge("analyze", "notify_user")
workflow.add_edge("notify_user", "plan")
workflow.add_edge("plan", "execute")
workflow.add_edge("execute", END)

supervisor_agent = workflow.compile()
