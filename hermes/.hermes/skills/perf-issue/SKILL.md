---
name: perf-issue
description: Diagnose and improve one measured performance problem.
disable-model-invocation: true
---

# Performance Issue

Handle one measured performance problem with a realistic workload and a before-and-after comparison. A sustained search against a target belongs to `hillclimb`.

## Procedure

1. Use `how` to ground the affected path and workload dimensions.
2. Establish a reproducible baseline and a regression gate.
3. Load `principle-prove-it-works` when a project `verify-*` skill may provide the representative workload. Consume its selection and evidence contract without yielding ownership of the metric or measurement method.
4. Profile or measure the matching surface.
5. Form one mechanism-based hypothesis.
6. Apply the smallest change that tests that hypothesis.
7. Measure before and after with the same harness.
8. Keep the change only when the improvement clears measurement noise and the regression gate stays green.
9. Promote to `architect` when the solution changes a boundary or data shape.

## Verification

The baseline, workload, metric, measurement command, before value, after value, and regression result are recorded. No claim rests on code inspection alone.
