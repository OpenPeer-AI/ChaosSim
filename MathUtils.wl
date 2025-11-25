(* ::Package:: *)

(* MathUtils.wl - Mathematical Utility Functions for ChaosSim *)
(* Reusable functions for Bernoulli numbers, Fibonacci sequences, and game theory *)

BeginPackage["MathUtils`"]


(* ::Section:: *)
(* Public Function Declarations *)

BernoulliChaosWeight::usage = "BernoulliChaosWeight[n] returns the absolute value of the nth Bernoulli number for chaos weighting."

GenerateFibonacciSequence::usage = "GenerateFibonacciSequence[n] generates the first n Fibonacci numbers."

GoldenRatioApproximation::usage = "GoldenRatioApproximation[n] calculates the golden ratio using the nth Fibonacci number."

PayoffMatrixRandom::usage = "PayoffMatrixRandom[rows, cols] generates a random payoff matrix for game theory."

NormalizeWeights::usage = "NormalizeWeights[list] normalizes a list to sum to 1."

ChaosEntropy::usage = "ChaosEntropy[data] calculates the Shannon entropy of chaos data."

LyapunovExponent::usage = "LyapunovExponent[data] estimates the Lyapunov exponent from a time series."


Begin["`Private`"]


(* ::Section:: *)
(* Bernoulli Number Utilities *)

BernoulliChaosWeight[n_Integer] := Module[{b},
  If[n < 0, 
    Return[0.001],
    b = BernoulliB[n];
    If[b == 0, 0.001, Abs[N[b]]]
  ]
]


(* Generate Bernoulli polynomial *)
BernoulliPolynomialValue[n_Integer, x_Numeric] := BernoulliB[n, x]


(* Weighted sum using Bernoulli numbers *)
BernoulliWeightedSum[values_List, maxOrder_Integer: 10] := Module[
  {weights, normalized},
  weights = Table[BernoulliChaosWeight[i], {i, 1, Min[maxOrder, Length[values]]}];
  normalized = weights / Total[weights];
  Total[Take[values, Length[normalized]] * normalized]
]


(* ::Section:: *)
(* Fibonacci Utilities *)

GenerateFibonacciSequence[n_Integer] := Table[Fibonacci[i], {i, 1, n}]


GoldenRatioApproximation[n_Integer] := Module[{fn, fnMinus1},
  If[n < 2, Return[1.0]];
  fn = Fibonacci[n];
  fnMinus1 = Fibonacci[n - 1];
  N[fn / fnMinus1]
]


(* Generate Lucas numbers (related to Fibonacci) *)
GenerateLucasSequence[n_Integer] := Table[LucasL[i], {i, 1, n}]


(* Fibonacci-based golden spiral parameters *)
FibonacciSpiralRadius[n_Integer] := Sqrt[Fibonacci[n]]


(* Calculate Fibonacci ratios for chaos analysis *)
FibonacciRatioSequence[depth_Integer] := Module[{fibs, ratios},
  fibs = GenerateFibonacciSequence[depth];
  ratios = Table[N[fibs[[i + 1]] / fibs[[i]]], {i, 1, depth - 1}];
  ratios
]


(* ::Section:: *)
(* Game Theory Utilities *)

PayoffMatrixRandom[rows_Integer, cols_Integer, range_List: {-10, 10}] := 
  RandomInteger[range, {rows, cols}]


(* Check if a strategy profile is a Nash equilibrium *)
IsNashEquilibrium[strategy_List, payoffMatrix1_List, payoffMatrix2_List] := Module[
  {i, j, isEquilibrium},
  {i, j} = strategy;
  
  isEquilibrium = True;
  
  (* Check if player 1 can improve *)
  If[Max[payoffMatrix1[[All, j]]] > payoffMatrix1[[i, j]],
    isEquilibrium = False
  ];
  
  (* Check if player 2 can improve *)
  If[Max[payoffMatrix2[[i, All]]] > payoffMatrix2[[i, j]],
    isEquilibrium = False
  ];
  
  isEquilibrium
]


(* Calculate expected payoff for mixed strategy *)
ExpectedPayoff[strategy1_List, strategy2_List, payoffMatrix_List] := 
  Sum[
    strategy1[[i]] * strategy2[[j]] * payoffMatrix[[i, j]],
    {i, 1, Length[strategy1]},
    {j, 1, Length[strategy2]}
  ]


(* Generate symmetric game payoff matrix *)
SymmetricPayoffMatrix[size_Integer] := Module[{matrix},
  matrix = PayoffMatrixRandom[size, size];
  (matrix + Transpose[matrix]) / 2
]


(* ::Section:: *)
(* General Chaos Analysis Utilities *)

NormalizeWeights[list_List] := Module[{total},
  total = Total[list];
  If[total == 0, Table[1/Length[list], Length[list]], list / total]
]


(* Calculate Shannon entropy *)
ChaosEntropy[data_List] := Module[{probs, bins, counts},
  bins = 20;
  counts = BinCounts[data, {Min[data], Max[data], (Max[data] - Min[data])/bins}];
  probs = NormalizeWeights[counts + 0.0001]; (* Add small value to avoid log(0) *)
  -Total[probs * Log[2, probs]]
]


(* Estimate Lyapunov exponent from time series *)
LyapunovExponent[data_List, delay_Integer: 1] := Module[
  {diffs, nonZeroDiffs, lyapunov},
  If[Length[data] < delay + 2, Return[0.0]];
  
  diffs = Abs[Differences[data, 1, delay]];
  nonZeroDiffs = Select[diffs, # > 0.00001 &];
  
  If[Length[nonZeroDiffs] < 2,
    Return[0.0],
    lyapunov = Mean[Log[nonZeroDiffs]]
  ];
  
  lyapunov
]


(* Calculate correlation dimension *)
CorrelationDimension[data_List, epsilon_Real: 0.1] := Module[
  {distances, correlationSum},
  distances = Flatten[DistanceMatrix[Partition[data, 1]]];
  correlationSum = Count[distances, x_ /; x < epsilon && x > 0];
  If[correlationSum > 0,
    Log[correlationSum] / Log[epsilon],
    0.0
  ]
]


(* Detect periodic orbits in chaos data *)
DetectPeriodicOrbit[data_List, tolerance_Real: 0.01] := Module[
  {n, periods, found},
  n = Length[data];
  found = False;
  periods = {};
  
  Do[
    If[Abs[data[[i]] - data[[1]]] < tolerance && i > 1,
      AppendTo[periods, i - 1];
      found = True
    ],
    {i, 2, Min[n, 100]}
  ];
  
  If[found, First[periods], 0]
]


(* Calculate Hurst exponent for long-range dependence *)
HurstExponent[data_List] := Module[{n, mean, std, ranges, scaledRanges},
  n = Length[data];
  mean = Mean[data];
  std = StandardDeviation[data];
  
  If[std == 0, Return[0.5]];
  
  ranges = Table[
    Max[Accumulate[Take[data, k] - mean]] - Min[Accumulate[Take[data, k] - mean]],
    {k, 10, n, Max[1, Floor[n/20]]}
  ];
  
  scaledRanges = ranges / (std * Sqrt[Range[10, n, Max[1, Floor[n/20]]]]);
  
  (* Fit log-log plot to estimate Hurst exponent *)
  If[Length[scaledRanges] > 2,
    Fit[
      Transpose[{Log[Range[10, n, Max[1, Floor[n/20]]]], Log[scaledRanges]}],
      {1, x}, x
    ][[2]],
    0.5
  ]
]


(* ::Section:: *)
(* Chaos Metrics and Analysis *)

ChaoticityScore[data_List] := Module[
  {entropy, lyapunov, hurst, score},
  entropy = ChaosEntropy[data];
  lyapunov = Abs[LyapunovExponent[data]];
  hurst = Abs[HurstExponent[data] - 0.5];
  
  (* Weighted combination *)
  score = 0.4 * entropy + 0.4 * lyapunov + 0.2 * hurst;
  score
]


(* Compare two chaos sequences *)
ChaosDistance[data1_List, data2_List] := Module[{minLen},
  minLen = Min[Length[data1], Length[data2]];
  EuclideanDistance[Take[data1, minLen], Take[data2, minLen]]
]


End[]

EndPackage[]


Print["MathUtils package loaded successfully."]
