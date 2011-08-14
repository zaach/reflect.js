
var person = {
  toString: function() {
    return this.firstName + ' ' + this.lastName;
  }
};

var man = person <| {
  sex: "male",
  toString: function() {
    return "Mr. " + super.toString();
  }
};

var jeremy = man <| {
  firstName: "Jeremy",
  lastName:  "Ashkenas"
};

jeremy.sex        // "male"
console.log(jeremy.toString()) // "Mr. Jeremy Ashkenas"

