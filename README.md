# ElixirProjects
Project work using Elixir

## Group Members
  - Ranbir Roshan 
  - Meghna 
  
## Actors Created
The following actors have been created as part of the project
1. **FindAllVampires** - The actor takes a starting and ending values as input and returns to its parent all the valid vampire number in the range
2. **FindPossibleFactors** - The actor would find all the valid numbers that can be a possible factor for a given number with the specified number of digits.
3. **FindVampireFangs** - Finds vampire fangs for a given number using the list of all possible factors. Ruturns empty map if there are none.

## Size of request for each actor
The following is the detail about work size for each actor.
1. **FindAllVampires** - The actor would just divide the range into half until a single number is reached. It also scale the stating number and end number to there respective valid range. 
So, it would be called once independently for each target number.
2. **FindPossibleFactors** - The actor takes a number and find all possible valid factors for the number with specified number of digits in target numbers. Ex. for a imput number 1234 and specified target number with 2 digits, the output would be a list containing 12, 13, 14, 21, 23, 24, 31, 32, 34, 41, 42, and 43.
So, it would be called once independently for each target number.
3. **FindVampireFangs** - The actor takes a single number. Gets the possible factors using "FindPossibleFactors" and then finds multiples that are fangs using binary division of all other factors.
So, it would be called once for each binary division of range or till the sequential execution window is reached.
  
## mix run proj1.exs 100000 200000
The output for the above is as follows:<br />
102510 201 510 201 510<br />
104260 260 401 260 401<br />
105210 210 501 210 501<br />
105264 204 516<br />
105750 150 705 150 705<br />
108135 135 801 135 801<br />
110758 158 701<br />
115672 152 761 152 761<br />
116725 161 725<br />
117067 167 701 167 701<br />
118440 141 840 141 840<br />
120600 201 600 201 600<br />
123354 231 534<br />
124483 281 443 281 443<br />
125248 152 824 152 824<br />
125433 231 543 231 543<br />
125460 204 615 246 510 246 510<br />
125500 251 500 251 500<br />
126027 201 627 201 627<br />
126846 261 486<br />
129640 140 926 140 926<br />
129775 179 725<br />
131242 311 422 311 422<br />
132430 323 410<br />
133245 315 423<br />
134725 317 425 317 425<br />
135828 231 588 231 588<br />
135837 351 387<br />
136525 215 635 215 635<br />
136948 146 938<br />
140350 350 401 350 401<br />
145314 351 414<br />
146137 317 461<br />
146952 156 942 156 942<br />
150300 300 501<br />
152608 251 608 251 608<br />
152685 261 585<br />
153436 356 431 356 431<br />
156240 240 651<br />
156289 269 581 269 581<br />
156915 165 951<br />
162976 176 926<br />
163944 396 414 396 414<br />
172822 221 782<br />
173250 231 750 231 750<br />
174370 371 470 371 470<br />
175329 231 759 231 759<br />
180225 225 801 225 801<br />
180297 201 897<br />
182250 225 810<br />
182650 281 650<br />
186624 216 864<br />
190260 210 906 210 906<br />
192150 210 915 210 915<br />
193257 327 591 327 591<br />
193945 395 491 395 491<br />
197725 275 719 275 719<br />
CPU Time: 38766 ms Real Time: 5110 ms. Ratio : 7.586301369863014<br />

## CPU time to REAL TIME ratio:
The CPU time to REAL TIME  ratio obtained is 7.6

## Largest problem solved
The largest problem solved with the code : 0 - 10,000,000
System Configuration:
Processor: Intel(R) Core(TM) i7-8705G CPU @ 3.10GHz 
RAM : 16 GB
Operating System: Windows (64 bit)
