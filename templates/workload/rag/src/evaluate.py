"""Run the evaluation questions through the RAG flow and fail below the groundedness threshold."""
import json
import os
import sys

from azure.ai.evaluation import AzureOpenAIModelConfiguration, GroundednessEvaluator

from rag import answer, credential


def main(questions_path="eval-questions.jsonl", threshold=None):
    threshold = float(threshold or os.environ.get("MIN_GROUNDEDNESS", "[[min_groundedness]]"))
    model_config = AzureOpenAIModelConfiguration(
        azure_endpoint=os.environ["AI_ENDPOINT"],
        azure_deployment=os.environ.get("CHAT_DEPLOYMENT", "chat"),
    )
    evaluator = GroundednessEvaluator(model_config, credential=credential())
    scores = []
    with open(questions_path, encoding="utf-8") as f:
        for line in f:
            if not line.strip():
                continue
            question = json.loads(line)["question"]
            response, context = answer(question)
            result = evaluator(query=question, response=response, context=context)
            score = float(result["groundedness"])
            scores.append(score)
            print(f"{score:.1f}  {question}")
    average = sum(scores) / len(scores)
    print(f"Average groundedness {average:.2f} (threshold {threshold})")
    if average < threshold:
        raise SystemExit("Quality gate failed: groundedness below the threshold")


if __name__ == "__main__":
    main(*sys.argv[1:])
