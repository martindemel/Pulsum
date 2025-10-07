# Creating Core ML Sentiment Model

To create the required `PulsumSentimentCoreML.mlmodel`:

1. Ensure Xcode tooling is installed (CreateML is required).
2. From this directory run `swift CreateSentimentModel.swift`.
3. Move the generated `PulsumSentimentCoreML.mlmodel` into this folder (overwriting any previous version).
4. Rebuild the project so SwiftPM bundles the updated resource.

Model specs:
- Task: 3-class wellness sentiment classifier (positive/neutral/negative)
- Input: Free-form journal text
- Output: Categorical label with calibrated confidence
- Training corpus: curated wellness statements (balanced across classes)







