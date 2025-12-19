app idea

modern rails 8 + hotwire for real time stuff (turbo) and js (stimulus)
sqlite for db (default)

transactions tracker where user creates transactions using natural language

- user lands on transactions index
- user types transaction in the form "spent 15 euros for coffee"
- user sees app is processing (new skeleton row appended marked as loading)
- new transaction form is free to use once again
- app starts background job and makes chatgpt process the input to create a transaction
- app creates transaction and user sees transaction appear magically

each user has multiple transactions and a transaction belongs to just one user
a transaction is composed of a date, amount and description