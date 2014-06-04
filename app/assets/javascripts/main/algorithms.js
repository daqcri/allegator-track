var algorithms = [
  {id:1, name: "General Parameters", params: [
    {name: 'Sources trustworthiness cosine Similarity Difference convegence sign', value: 0.001, dataType: 'double', min: 0, max: 0.1, desc: 'the difference of the sources trustworthinessthe cosine similarity between two iterrations must be less than this value for a convergence sign.'},
    {name: 'Starting Trustworthiness', value: 0.8, dataType: 'double' , min: 0, max: 1.0, desc: 'The initial value for all sources trustworthiness.'},
  ]},
  {id:2, name: "Cosine", params: [
    {name: 'Starting Confidence', value: 1, dataType: 'double', min: 0, max: 1.0, desc: "The initial value's confidence for all properties values."},
    {name: 'Dampening Factor', value: 0.2, dataType: 'double', min: 0, max: 1, desc: 'Trustworthiness dampening factor.'},
  ]},
  {id:3, name: "2-Estimates", params: [
    {name: 'Normalization Weight', value: 0.5, dataType: 'double', min: 0, max: 1, desc: "The weight used for normalizing sources' trustworthiness and values' confidence"},
  ]},
  {id:4, name: "3-Estimates", params: [
    {name: 'Starting Error Factor', value: 0.4, dataType: 'double' , min: 0, max: 1.0, desc: "The initial value's error factor for all properties values."},
    {name: 'Normalization Weight', value: 0.5, dataType: 'double', min: 0, max: 1, desc: "The weight used for normalizing sources' trustworthiness and values' confidence"},
  ]},
  {id:5, name: "Depen", params: [
    {name: 'alpha', value: 0.2, dataType: 'double', min: 0, max: 0.5, desc: 'The a-priori probability that two data sources are dependent.'},
    {name: 'c', value: 0, dataType: 'double', min: 0, max: 1, desc: 'The probability that a value provided by a copier is copied.'},
    {name: 'n', value: 100, dataType: 'int', min: 1, desc: 'The number of false values in the underlying domain for each object.'},
  ]},
  {id:6, name: "Accu", params: [
    {name: 'alpha', value: 0.2, dataType: 'double', min: 0, max: 0.5, desc: 'The a-priori probability that two data sources are dependent.'},
    {name: 'c', value: 0, dataType: 'double', min: 0, max: 1, desc: 'The probability that a value provided by a copier is copied.'},
    {name: 'n', value: 100, dataType: 'int', min: 1, desc: 'The number of false values in the underlying domain for each object.'},
  ]},
  {id:7, name: "AccuSim", params: [
    {name: 'alpha', value: 0.2, dataType: 'double', min: 0, max: 0.5, desc: 'The a-priori probability that two data sources are dependent.'},
    {name: 'c', value: 0, dataType: 'double', min: 0, max: 1, desc: 'The probability that a value provided by a copier is copied.'},
    {name: 'n', value: 100, dataType: 'int', min: 1, desc: 'The number of false values in the underlying domain for each object.'},
  ]},
  {id:8, name: "AccuNoDep", params: [
    {name: 'alpha', value: 0.2, dataType: 'double', min: 0, max: 0.5, desc: 'The a-priori probability that two data sources are dependent.'},
    {name: 'c', value: 0, dataType: 'double', min: 0, max: 1, desc: 'The probability that a value provided by a copier is copied.'},
    {name: 'n', value: 100, dataType: 'int', min: 1, desc: 'The number of false values in the underlying domain for each object.'},
  ]},
  {id:9, name: "TruthFinder", params: [
    {name: 'Similarity Constant', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'Percentage of the similarity betwen the values that will be added to the value confidence.'},
  ]},
  {id:10, name: "Simple LCA and Guess LCA", params: [
    {name: 'Bita1', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'The prior truth probability of the claimed value.'},
  ]},
  {id:11, name: "MLE", params: [
    {name: 'Bita1', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'Overall prior truth probability of the claims.'},
    {name: 'r', value: 0.5, dataType: 'double', min: 0, max: 1, desc: 'The probability that a source provides a value for all data items.'},
  ]},
]
