---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea to stress-test their thinking.
disable-model-invocation: true
---

Interview me relentlessly about every aspect of this until we reach a shared understanding. Walk down each branch of the decision tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Before writing any question, check the environment (filesystem, installed tools, OS, config files, etc.) for every fact you can find there. Never ask me a fact you can look up yourself (e.g. OS, package versions, file contents). Only *decisions* are mine to make.

Ask all remaining questions — the decisions — together in the first message, as plain text, not via a UI/tool prompt. Wait for feedback on each question before continuing.

Do not act on it until I confirm we have reached a shared understanding.
