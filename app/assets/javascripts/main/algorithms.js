var algorithms = [
  {id:1, name: "General Parameters", description: "description about algorithm", params: [
    {name: 'Convergence test threshold', value: 0.001, dataType: 'double', min: 0, max: 0.1, desc: 'The difference of source truthworthiness cosine similarity between two successive iterations should be less than the user-defined threshold.'},
    {name: 'Initial sources truthworthiness', value: 0.8, dataType: 'double' , min: 0, max: 1.0, desc: 'The initial value for all sources truthworthiness.'},
  ]},
  {id:2, name: "Cosine", description: "description about algorithm", params: [
    {name: 'Starting Confidence', value: 1, dataType: 'double', min: 0, max: 1.0, desc: "The initial confidence for all properties values."},
    {name: 'Dampening Factor', value: 0.2, dataType: 'double', min: 0, max: 1, desc: 'Trustworthiness dampening factor.'},
  ]},
  {id:3, name: "2-Estimates", description: "description about algorithm", params: [
    {name: 'Normalization Weight', value: 0.5, dataType: 'double', min: 0, max: 1, desc: "The weight used for normalizing sources' trustworthiness and values' confidence"},
  ]},
  {id:4, name: "3-Estimates", description: "description about algorithm", params: [
    {name: 'Starting Error Factor', value: 0.4, dataType: 'double' , min: 0, max: 1.0, desc: "The initial value's error factor for all properties values."},
    {name: 'Normalization Weight', value: 0.5, dataType: 'double', min: 0, max: 1, desc: "The weight used for normalizing sources' trustworthiness and values' confidence"},
  ]},
  {id:5, name: "Depen", description: "description about algorithm", params: [
    {name: 'alpha', value: 0.2, dataType: 'double', min: 0, max: 0.5, desc: 'The a-priori probability that two data sources are dependent.'},
    {name: 'c', value: 0, dataType: 'double', min: 0, max: 1, desc: 'The probability that a value provided by a copier is copied.'},
    {name: 'n', value: 100, dataType: 'int', min: 1, desc: 'The number of false values in the underlying domain for each object.'},
  ]},
  {id:6, name: "Accu", description: "description about algorithm", params: [
    {name: 'alpha', value: 0.2, dataType: 'double', min: 0, max: 0.5, desc: 'The a-priori probability that two data sources are dependent.'},
    {name: 'c', value: 0, dataType: 'double', min: 0, max: 1, desc: 'The probability that a value provided by a copier is copied.'},
    {name: 'n', value: 100, dataType: 'int', min: 1, desc: 'The number of false values in the underlying domain for each object.'},
  ]},
  {id:7, name: "AccuSim", description: "description about algorithm", params: [
    {name: 'alpha', value: 0.2, dataType: 'double', min: 0, max: 0.5, desc: 'The a-priori probability that two data sources are dependent.'},
    {name: 'c', value: 0, dataType: 'double', min: 0, max: 1, desc: 'The probability that a value provided by a copier is copied.'},
    {name: 'n', value: 100, dataType: 'int', min: 1, desc: 'The number of false values in the underlying domain for each object.'},
  ]},
  {id:8, name: "AccuNoDep", description: "description about algorithm", params: [
    {name: 'alpha', value: 0.2, dataType: 'double', min: 0, max: 0.5, desc: 'The a-priori probability that two data sources are dependent.'},
    {name: 'c', value: 0, dataType: 'double', min: 0, max: 1, desc: 'The probability that a value provided by a copier is copied.'},
    {name: 'n', value: 100, dataType: 'int', min: 1, desc: 'The number of false values in the underlying domain for each object.'},
  ]},
  {id:9, name: "TruthFinder", description: "description about algorithm", params: [
    {name: 'Similarity Constant', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'Percentage of the similarity betwen the values that will be added to the value confidence.'},
  ]},
  {id:10, name: "SimpleLCA", description: "description about algorithm", params: [
    {name: 'Prior truth probability', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'The prior truth probability of the claimed value.'},
  ]},
  {id:11, name: "GuessLCA", description: "description about algorithm", params: [
    {name: 'Prior truth probability', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'The prior truth probability of the claimed value.'},
  ]},
  {id:12, name: "MLE", description: "description about algorithm", params: [
    {name: 'Prior truth probability', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'Overall prior truth probability of the claims.'},
    {name: 'r', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'The probability that a source provides a value for all data items.'},
  ]},
  {id:13, name: "LTM", description: "description about algorithm", params: [
    {name: 'Number Of Iterations', value: 500, dataType: 'int', min: 1, max: 10000, desc: 'Number of Iterations.'},
    {name: 'Burn-in', value: 100, dataType: 'int', min: 1, max: 1000, desc: 'Collapsed Gibbs Sampling burn-in period (Number of discarded first set of iterations).'},
    {name: 'Thinning', value: 9, dataType: 'int', min: 1, max: 1000, desc: 'Collapsed Gibbs Sampling thinning parameter (Number of iterations to be skipped every time before considering an iteration result).'},
    {name: 'prior true count', value: 0.5, dataType: 'double', min: 0.0, max: 1.0, desc: 'prior true count'},
    {name: 'prior false count', value: 0.5, dataType: 'double', min: 0.0, max: 1.0, desc: 'prior false count.'},
    {name: 'Prior false positive count', value: 0.9, dataType: 'double', min: 0.0, max: 1.0, desc: 'Prior false positive count.'},
    {name: 'prior true negative count', value: 0.1, dataType: 'double', min: 0.0, max: 1.0, desc: 'prior true negative count.'},
    {name: 'Prior true positive count', value: 0.9, dataType: 'double', min: 0.0, max: 1.0, desc: 'Prior true positive count.'},
    {name: 'prior false negative count', value: 0.1, dataType: 'double', min: 0.0, max: 1.0, desc: 'prior false negative count.'},
  ]},
]
