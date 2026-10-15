# LLMOps quality gate

LLMOps adds evaluation to the delivery pipeline. A fixed set of test questions is run through the full retrieval and answer flow on every change. An evaluator model scores each answer for groundedness, which measures whether the answer is supported by the retrieved passages.

The pipeline compares the average groundedness score with a threshold. If the score is below the threshold the pipeline fails, so a change that degrades answer quality does not reach the next environment.
