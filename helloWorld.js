'use strict';
console.log('Loading event');

exports.handler = function(event, context, callback) {
  var name = (event.name === undefined ? 'No-Name' : event.name);
  console.log('"Hello":"' + name + '"');
  callback(null, {"Hello":name}); // SUCCESS with message
};
