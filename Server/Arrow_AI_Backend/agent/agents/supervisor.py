"""
Supervisor Agent - Main workflow orchestrator
Routes requests through complexity analysis → planning → execution → decision
"""

from Arrow_AI_Backend.agent.agents.complexity_analyzer import complexity_analyzer
from Arrow_AI_Backend.agent.agents.executor import agent_executor
from Arrow_AI_Backend.agent.agents.planner import planner
from Arrow_AI_Backend.agent.agents.decider import decider
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
    """Execute the current task (first task in remaining plan)"""
    plan = state["plan"]
    task = plan[0]
    
    response_text = f"✓ Successfully completed: {task}"
    
    await manager.send(state["session_id"], {
        "type": "chat_response",
        "message": response_text
    })
    
    return {
        "past_steps": [(task, response_text)],
    }


# ========== Step 5: Decide Next Action ==========
async def decide_step(state: PlanExecute):
    """Decide how many tasks are complete and what to do next"""
    decision = await decider.ainvoke(state)
    
    completed_count = decision.completed_count
    current_plan = state["plan"]
    
    remaining_plan = current_plan[completed_count:]
    
    if decision.is_replan_needed:
        return {
            "plan": remaining_plan,
            "replan_reason": decision.replan_reason
        }
    
    if len(remaining_plan) == 0:
        await manager.send(state["session_id"], {
            "type": "chat_response",
            "message": decision.final_message or "All tasks completed!"
        })
        return {
            "plan": remaining_plan,
            "response": decision.final_message or "All tasks completed!"
        }
    
    return {
        "plan": remaining_plan
    }


# ========== Routing Function ==========
def route_after_decision(state: PlanExecute):
    """After decision: continue to execute, replan, or end"""
    if state.get("replan_reason"):
        return "plan"
    elif len(state.get("plan", [])) == 0:
        return END
    else:
        return "execute"


# ========== Build Workflow ==========
workflow = StateGraph(PlanExecute)

workflow.add_node("analyze", analyze_complexity)
workflow.add_node("notify_user", notify_user)
workflow.add_node("plan", plan_step)
workflow.add_node("execute", execute_step)
workflow.add_node("decide", decide_step)

workflow.add_edge(START, "analyze")
workflow.add_edge("analyze", "notify_user")
workflow.add_edge("notify_user", "plan")
workflow.add_edge("plan", "execute")
workflow.add_edge("execute", "decide")

workflow.add_conditional_edges(
    "decide",
    route_after_decision,
    ["execute", "plan", END]
)

supervisor_agent = workflow.compile()
