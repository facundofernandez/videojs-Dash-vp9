var express = require('express');
var path = require('path');
var app = express();

app.use('/', express.static(__dirname + '/public'));

app.get('/', function (req, res) {
  res.render('index');
});

app.get('/key', function (req, res) {
    console.log(req.query);
    if(req.query.userId !== '123'){
        res.send('Acceso denegado')
    }else{
        var options = {
            root: __dirname + '/public/',
            dotfiles: 'deny',
            headers: {
                'x-timestamp': Date.now(),
                'x-sent': true
            }
          };
        res.sendFile('enc.key',options)
        
    }
    
  });
  


app.listen(3000, function () {
  console.log('Example app listening on port 3000!');
});