// Self-test: exercise store pure functions with fake storage.
const assert = require("assert");
const S = require("./store.js");

// fake storage
const fakeStorage = (() => {
  const m = {};
  return {
    getItem: (k) => (k in m ? m[k] : null),
    setItem: (k, v) => { m[k] = String(v); },
  };
})();

// add
let todos = [];
todos = S.addTodo(todos, "buy coffee");
todos = S.addTodo(todos, "  water plants  ");
todos = S.addTodo(todos, "   "); // blank ignored
assert.deepStrictEqual(todos, [
  { text: "buy coffee", done: false },
  { text: "water plants", done: false },
]);

// toggle
const toggled = S.toggleTodo(todos, 0);
assert.strictEqual(toggled[0].done, true);
assert.strictEqual(toggled[1].done, false);
assert.strictEqual(todos[0].done, false, "pure: original untouched");
assert.strictEqual(S.toggleTodo(toggled, 0)[0].done, false, "toggle back");

// remove
const removed = S.removeTodo(toggled, 0);
assert.deepStrictEqual(removed, [{ text: "water plants", done: false }]);
assert.strictEqual(toggled.length, 2, "pure: original untouched");

// round-trip serialize
assert.deepStrictEqual(S.deserialize(S.serialize(toggled)), toggled);

// save/load via fake storage
S.save(fakeStorage, toggled);
assert.deepStrictEqual(S.load(fakeStorage), toggled);

// load from empty/corrupt storage
assert.deepStrictEqual(S.load({ getItem: () => null }), []);
assert.deepStrictEqual(S.deserialize("not json"), []);
assert.deepStrictEqual(S.deserialize('{"a":1}'), []);

console.log("todo-scratchpad selftest OK");
