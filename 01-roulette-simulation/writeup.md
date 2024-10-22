---
title: "Blog Post - Roulette Simulation"
output: html_document
---

```{r setup, include=FALSE}

knitr::knit_hooks$set(inline = function(x) { knitr:::format_sci(x, 'md')})
knitr::opts_chunk$set(echo = TRUE, cache = TRUE)

# This section loads necessary R libraries and sources scripts that define 
# useful functions format_md.

library(pacman)
library(viridis)
options(tigris_use_cache = TRUE)
p_load(tidyverse, httr, rio, geojson, tigris, mapview, tidycensus, geojsonio, jsonlite, stringr, sf, broom)

```

## Introduction

Roulette is a casino game of chance, named after the French word meaning "little wheel." The roulette wheel is divided into 38 evenly sized sections, and are either green, red or black, and are each numbered. During each play, a pocket is randomly selected. The gambler has the option to bet on several different outcomes, such as a specific number, color or whether the number that will be chosen is odd or even. For the purposes of this study, the bet being waged is only related to color, where 18 pockets are red, 18 are black and 2 are green. 

Upon winning a bet on black (or red), the payout is $1 for each dollar bet. In this simulation, we will try and determine the effectiveness of the Martingale strategy for playing Roulette. In this strategy, the player doubles the bet after every loss, so that the first win will recoup all the losses in the bets thus far, and make a profit equivalent to the original bet. There are a few issues with this strategy, such as the player going bankrupt, losing multiple times in a row, or hitting the casino wager or play limit.

In the first few iterations of the Martingale strategy, it seems like it always ends in positive earnings. The simulation we will make for this strategy will help determine whether this strategy is actually profitable. In the program, we will first design functions that run a scenario of each play, and then create functions that runs a series of plays until the point certain stopping conditions are met, that force the game to end. 

## Programming the Simulation

First, we need a function that runs a single play of the Martingale strategy. This function will take in a state list, which are the preset conditions under which the game is being played, spins the roulette wheel and returns updated values of these present conditions, or operating characteristics, following that single play of the game. 
```{r one_play, include=TRUE}

#' A single play of the Martingale strategy
#'
#' Takes a state list, spins the roulette wheel, returns the state list with updated values (for example, budget, plays, etc)
#' @param state A list with the following entries: 
#'   B              number, the budget
#'   W              number, the budget threshold for successfully stoping
#'   L              number, the maximum number of plays 
#'   M              number, the casino wager limit
#'   plays          integer, the number of plays executed
#'   previous_wager number, the wager in the previous play (0 at first play)
#'   previous_win   TRUE/FALSE, indicator if the previous play was a win (TRUE at first play)
#' @return The updated state list
one_play <- function(state){
  
    # Wager
    proposed_wager <- ifelse(state$previous_win, 1, 2*state$previous_wager)
    wager <- min(proposed_wager, state$M, state$B)
    
    # Spin of the wheel
    red <- rbinom(1,1,18/38)
    
    # Update state
    state$plays <- state$plays + 1
    state$previous_wager <- wager
    if(red){
      # WIN
      state$B <- state$B + wager
      state$previous_win <- TRUE
    }else{
      # LOSE
      state$B <- state$B - wager
      state$previous_win <- FALSE
    }
  state
}
```

The above function runs a single play of roulette under the Martingale strategy. The function takes in a set of parameters, which dictate the rules of how the game will be played. The list of parameters is below. 

* B              Budget (number)
* W              Winning Threshold (number) 
* L              Maximum number of plays (number)
* M              Wager Limit (number)
* plays          Number of plays executed (integer)
* previous_wager Wager in previous play (0 at first play) (number)
* previous_win   Indicator if the previous play was a win (TRUE at first play) (TRUE/FALSE)

The function has creates a variable to determine the wager to be proposed based on the Martingale strategy, double the losses from the previous play, or $1 if the previous play was a win. The wager bet will be the minimum of this proposed wager based on the strategy, the Maximum wager limit (M) or the budget (B). 

In this simulation, we are betting on red, and the roulette wheel is "spun" using a binomial distribution to generate a random win or loss based on the distribution of the colors on the wheel (18/38 for red). The input parameters, or operating characteristics are updated based on whether the spin of the wheel resulted in red or a different color. In the end of this run, previous_win is updated to reflect TRUE or FALSE depending on if the spin resulted in a red or not, previous_wager is updated to reflect the last played bet, and the budget, B, is updated to reflect the gain or loss of money as a result of the spin. 

Next, in order to run multiple simulations of this single run, to create a series of runs, a Stopping rule must be programmed in order to stop the game when certain conditions arise. The player will keep playing the Martingale strategy until the conditions listed below are met: 

* The player has W dollars (Winning Threshold)
* The player goes bankrupt (B <= 0)
* The player completes L wagers (Maximum number of plays allowed)

The code below creates a function that determines if the gambler has to stop playing.

``` {r Stopping_rule, include=TRUE}
#' Stopping rule
#'
#' Takes the state list and determines if the gambler has to stop
#' @param state A list.  See one_play
#' @return TRUE/FALSE
stop_play <- function(state){
  if(state$B <= 0) return(TRUE)
  if(state$plays >= state$L) return(TRUE)
  if(state$B >= state$W) return(TRUE)
  FALSE
}

```

THe function takes in the parameters after each play and returns are boolean value (TRUE or FALSE), to allow further gameplay or stop the game. It checks whether the parameters meet certain conditions and returns TRUE if they do. Otherwise it returns FALSE and the game is stopped there. 

Now that we have a function to help stop the game when it meets certain conditions, we can create a function that takes in the same parameters and runs a series of games until the stopping criteria are met. 

``` {r one_series, include=TRUE}
#' Play roulette to either bankruptcy, success, or play limits
#'
#' @param B number, the starting budget
#' @param W number, the budget threshold for successfully stoping
#' @param L number, the maximum number of plays 
#' @param M number, the casino wager limit
#' @return A vector of budget values calculated after each play.
one_series <- function(
    B = 200
  , W = 300
  , L = 1000
  , M = 100
){

  # initial state
  state <- list(
    B = B
  , W = W
  , L = L
  , M = M
  , plays = 0
  , previous_wager = 0
  , previous_win = TRUE
  )
  
  # vector to store budget over series of plays
  budget <- rep(NA, L)
  
  # For loop of plays
  for(i in 1:L){
    new_state <- state %>% one_play
    budget[i] <- new_state$B
    if(new_state %>% stop_play){
      return(budget[1:i])
    }
    state <- new_state
  }
  budget    
}
```

The above function takes in parameters that set up the game, such as starting budget B, the winning threshold W, the maximum number of plays allowed L, and the maximum allowed wager M. 

It sets the initial state of the game, setting the number of plays and previous_wager to 0, and previous_win to true to allow the game to start. It stores the budget over a series of plays in a vector, or list, called "budget". 

The function runs a loop of plays until the stopping conditions are met, and stores the results in the "budget" vector. 

``` {r helper_function, include=TRUE}
# helper function
get_last <- function(x) x[length(x)] 

```

The above function is a helper function that gives the very last value of a varaible in the resutl of any function. 

We can now run a simulation, that runs multiple series of the games of roulette following the Martingale strategy to determine how effective it is in always resulting in a profit, given the set parameters. 

```{r simulation, include=TRUE}
# Simulation
walk_out_money <- rep(NA, 100)
for(j in seq_along(walk_out_money)){
  walk_out_money[j] <- one_series(B = 200, W = 300, L = 1000, M = 100) %>% get_last
}

# Walk out money distribution
hist(walk_out_money, breaks = 100)

# Estimated probability of walking out with extra cash
mean(walk_out_money > 200)

# Estimated earnings
mean(walk_out_money - 200)
```

The above code runs a simulation of the function running a series of plays until stopping conditions are met. The code outputs the money the player walks out with at the end of the repeated simulations. As the result of each play is determined by a random binomial distribution, the results of each run of this simulation varies each time. The amount of money the player walks out with is stored in a data frame, and can then be used to determine the probability of walking out with extra cash, and can also be used to determine the average earnings at the end of 'n' simulations. 

As can be seen from the results of the run of the simulation, the estimated probability of walking out with extra cash is always somewhere around 50%, and the estimated earnings are all almost negative, as the stopping conditions were met before a winning wager was made. 

A plot of the gamblers winnings or losses over time over a series of wagers at the roulette wheel can be found below. 

``` {r earnings_over_time, include=TRUE}
#WagerNo/Earnings

budget <- rep(NA,20)
for(a in 1:20) {
  budget[a] <- one_series(B = 200, W = 300, L = 1000, M = 100)[a*10]
}

plot (seq(10,200,10), budget-200, xlab = "Number of Plays", ylab = "Earnings" )

```

The graph above plots the earnings every 10 plays. The graph indicates that there is a lot of variation in the earnings and losses using this strategy, and profit is not necessarily a guranteed outcome while playing this strategy at the roulette table. The results above, including the histogram all indicate that more often than not, this strategy ends in a loss, with estimated earnings negative most of time the simuation was run, and close to 50% winning chances. 

While this strategy might be effective sometimes, it does not gurantee success given the results of these simulations under these conditions. 

Changing the parameters of simulation and the inputs to the functions does have an impact on the resulting earnings. The below functions change one of the variables L, M, B or W to create plots and determine how the results change. 

``` {r changing_variableL, include=TRUE}
#Changing a variable L
walk_out_money1 <- rep(NA, 10)
for(j in 1:10){
  walk_out_money1[j] <- one_series(B = 200, W = 300, L = j*100, M = 100) %>% get_last
}
plot(x=seq(100,1000,100), y=walk_out_money1, xlab = "Number of Plays", ylab = "Earnings")
```

``` {r changing_variableM, include=TRUE}
#Changing a variable M
walk_out_money2 <- rep(NA, 10)
for(j in 1:10){
  walk_out_money2[j] <- one_series(B = 200, W = 300, L = 1000, M = j*10) %>% get_last
}
plot(x=seq(10,100,10), y=walk_out_money2, xlab = "Number of Plays", ylab = "Earnings")
```

``` {r changing_variableB, include=TRUE}
#Changing a variable B
walk_out_money3 <- rep(NA, 10)
for(j in 1:10){
  walk_out_money3[j] <- one_series(B = j*20, W = 300, L = 1000, M = 100) %>% get_last
}
plot(x=seq(10,100,10), y=walk_out_money3, xlab = "Number of Plays", ylab = "Earnings")
```

``` {r changing_variableW, include=TRUE}
#Changing a variable W
walk_out_money4 <- rep(NA, 10)
for(j in 1:10){
  walk_out_money4[j] <- one_series(B = 200, W = j*30, L = 1000, M = 100) %>% get_last
}
plot(x=seq(10,100,10), y=walk_out_money4, xlab = "Number of Plays", ylab = "Earnings")
```

It can be seen from the plots above that changes in each of these three input parameters, or operating characteristics leads to some changes in the resulting output. 

This simulation can also be used to determine the average number of plays that take place under these set condition before the game is stopped. 

``` {r average_plays_before_stopping, include=TRUE}
#Estimated average plays before stopping
stopping_plays <- rep(NA, 1000)
 for(i in seq_along(stopping_plays)){
   stopping_plays[i] <- length(one_series(B = 200, W = 300, L = 1000, M = 100))
 }
mean(stopping_plays)
```

This function runs multiple series of the games, and takes the mean of the average length (number of plays) at which the games were stopped. Most series stop at around 200 plays given these parameters. 

## Limitations and Uncertainties

Simulations themselves are approxiamtions of a real scenario and are limited in scope to the number of times the simulation is run. This simulation only runs a finite number of times on certain set parameters. More iterations with different combinations to account for all scenarios would make this simulation more accurate. 
