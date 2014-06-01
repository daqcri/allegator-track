var algorithms = [
  {id:1, name: "General Parameters", params: [
    {name: 'cosineSimDiffStoppingCriteria', value: 0.001, dataType: 'double', min: 0, max: 1.0, desc: 'put description here'},
    {name: 'startingTrust', value: 0.8, dataType: 'double' , min: 0, max: 1.0, desc: 'put description here'},
    {name: 'startingErrorFactor', value: 0.4, dataType: 'double' , min: 0, max: 1.0, desc: 'put description here'},
    {name: 'startingConfidence', value: 1, dataType: 'double', min: 0, max: 1.0, desc: 'put description here'},
  ]},
  {id:2, name: "Cosine", params: [
    {name: 'ampeningFactorCosine', value: 0.2, dataType: 'double', min: 0, max: 1, desc: 'put description here'},
  ]},
  {id:3, name: "2-Estimates", params: [
    {name: 'normalizationWeight', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'put description here'},
  ]},
  {id:4, name: "3-Estimates", params: [
    {name: 'normalizationWeight', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'put description here'},
  ]},
  {id:5, name: "Depen", params: [
    {name: 'alpha', value: 0.2, dataType: 'double', min: 0, max: 0.5, desc: 'put description here'},
    {name: 'c', value: 0, dataType: 'double', min: 0, max: 1, desc: 'put description here'},
    {name: 'n', value: 100, dataType: 'int', min: 1, desc: 'put description here'},
  ]},
  {id:6, name: "Accu", params: [
    {name: 'alpha', value: 0.2, dataType: 'double', min: 0, max: 0.5, desc: 'put description here'},
    {name: 'c', value: 0, dataType: 'double', min: 0, max: 1, desc: 'put description here'},
    {name: 'n', value: 100, dataType: 'int', min: 1, desc: 'put description here'},
  ]},
  {id:7, name: "AccuSim", params: [
    {name: 'alpha', value: 0.2, dataType: 'double', min: 0, max: 0.5, desc: 'put description here'},
    {name: 'c', value: 0, dataType: 'double', min: 0, max: 1, desc: 'put description here'},
    {name: 'n', value: 100, dataType: 'int', min: 1, desc: 'put description here'},
  ]},
  {id:8, name: "AccuNoDep", params: [
    {name: 'alpha', value: 0.2, dataType: 'double', min: 0, max: 0.5, desc: 'put description here'},
    {name: 'c', value: 0, dataType: 'double', min: 0, max: 1, desc: 'put description here'},
    {name: 'n', value: 100, dataType: 'int', min: 1, desc: 'put description here'},
  ]},
  {id:9, name: "TruthFinder", params: [
    {name: 'similarityConstant', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'put description here'},
  ]},
  {id:10, name: "Simple LCA and Guess LCA", params: [
    {name: 'Bita1', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'put description here'},
  ]},
  {id:11, name: "MLE", params: [
    {name: 'Bita1', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'put description here'},
    {name: 'r', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'put description here'},
  ]},
]
