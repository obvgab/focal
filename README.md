# Focal
Focal is a SwiftUI-based application that shows the world through a lens of colorblindness and daltonization.

Color Vision Deficiency affects up to 1 in 12 males and 1 in 200 females, wherein most lose parts of the green-red spectrum. Daltonization aims to remedy this issue through altering the colorspace and exposing areas that dichromats and color deficient individuals usually cannot see.

This application makes use of Nvidia's Temporally Stable Daltonization technique, alongisde Machado et al.'s CVD simulation technique.

Next tasks:
- Implement a neural network using MLX to learn an individual's color perception
- Apply MLX model to current Metal-based render pipeline
- Add tritan deficiencies
    - Transforms (since Nvidia did not cover tritan in their paper)
    - MLX Model

