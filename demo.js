var diff = require('diff');
var x = 'admin xadsa admin';
var y = 'user xadsa admin extracly';
var di = diff.diffChars(x,y);

var str = "";

var position = 0;

// Compressing the data
for (var i = 0; i < di.length; i ++) {
  if(di[i]['added'] == undefined && di[i]['removed'] == undefined) {
    di[i]['value'] = null;
  }
}

console.log(di);

// Regenerate the data

for (var i = 0; i < di.length; i ++) {
  if (di[i]['added'] == true ) {
    str += di[i]['value'];
  } else if (di[i]['removed'] == undefined){
    str += x.slice(position, position + di[i]['count']);
    position += di[i]['count'];
  } else {
    position += di[i]['count'];
  }
}
console.log(str);
