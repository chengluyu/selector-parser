const SelectorParser = require('../lib');
const yaml = require('yaml');

const show = x => console.log(yaml.stringify(x));

show(SelectorParser.parse('p'));
show(SelectorParser.parse('.button'));
show(SelectorParser.parse('#container'));
show(SelectorParser.parse('button.primary#close'));
show(SelectorParser.parse('button#close.primary'));
