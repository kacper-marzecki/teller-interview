# Teller Interview
The app is hosted on heroku free tier, so it may require some time to start up.

# Token structure & generation:
test_{seed}
seed - a string that is used to compute input to generating accounts, transactions etc.

To generate token: `echo test_1234: | base64`
`curl https://teller-interview.herokuapp.com/accounts/ -H "Authorization: Bearer dGVzdF8xMjM0Ogo="`


# Generation strategy:
There are 2 valid strategies I considered:
- using the token as an input to a pseudo-random generator (e.g. using :rand module).
    Each generation would produce another seed, used for further computations. 
    This would produce a truly pseudo-random chain of transaction amounts etc. but at a cost.
    When increasing the number of transactions per day and assuming a client could use a token generated years ago, 
    to ensure the same result we would have to compute all transactions up to present day.
    
- using pre-determined lists of transaction amounts etc., and ~randomizing them by using the token to compute an offset from which transactions are consumed.
    This allows for computing the sum of transaction amounts before the visible time window in constant time.
    This approach seemed more interesting so I decided to implement it. 

# Request count per path Live View
available under https://teller-interview.herokuapp.com/ 