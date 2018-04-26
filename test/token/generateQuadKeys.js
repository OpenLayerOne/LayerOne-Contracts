
String.prototype.replaceAt=function(index, replacement) {
    return this.substr(0, index) + replacement+ this.substr(index + replacement.length);
  }
  
const generateQuadKeys = (num, lastKey, keys) => {
    if (num == 0) {
      return keys
    }
    let newKey = lastKey
    for (let i = 1; i<=16; i++) {
      let last = Number(newKey.substr(-i, 1))
      if (last == 3 ) {
        newKey = newKey.replaceAt(16-i, "0")
      } else {
        newKey = newKey.replaceAt(16-i, String(last + 1))
        keys.push(newKey)
        return generateQuadKeys(num - 1, newKey, keys)
      }
    }
  }

  module.exports = generateQuadKeys

