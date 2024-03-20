//
//  EE139A4D-B958-4D3E-95B4-79846DFB4346: 11:43 3/20/24
//  TunedTransform.swift by Gab
//  

import MLX

// Eventually use Oklab distance tests to provide personalized daltonization
// Should run a machine learning model to adjust colors from original.png
// Then we can use the texture filtering method from before
// This should make it a slow initial compute, but fast afterwards
// Colors shouldn't really change over time for temporal stability
