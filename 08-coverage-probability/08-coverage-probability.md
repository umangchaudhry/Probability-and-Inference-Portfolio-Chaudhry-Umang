Coverage probability
====================

Coverage probability is an important operating characteristic of methods
for constructing interval estimates, particularly confidence intervals.

**Definition:** For the purposes of this deliverable, define the 95%
confidence interval of the mean to be the middle 95% of sampling
distribution of the mean. Similarly, the 95% confidence interval of the
median, standard deviation, etc. is the middle 95% of the respective
sampling distribution.

**Definition:** For the purposes of this deliverable, define the
coverage probability as the long run proportion of intervals that
capture the population parameter of interest. Conceptualy, one can
calculate the coverage probability with the following steps

1.  generate a sample of size *N* from a known distribution
2.  construct a confidence interval
3.  determine if the confidence captures the population parameter
4.  Repeat steps (a) - (c) many times. Estimate the coverage probability
    as the proportion of samples in which the confidence interval
    captured the population parameter.

The figure below shows the 95% confidence interval calculated for a
handful of samples. Intervals in blue capture the population parameter
of interest; intervals in red do not.

![](./assets/coverage-prob.svg)

Idealy, a 95% confidence interval will capture the population parameter
of interest in 95% of samples.

Assignment
----------

In this assignment, you will perform a simulation to calculate the
coverage probability of the 95% confidence interval of the median when
computed from *F̂*<sub>*X*</sub><sup>*m**l**e*</sup>. You will write a
blog post to explain coverage probability and to explain your
simulation.

The audience of your blog post is a Senior Data Scientist who you hope
to work with in the future.

Suggested steps
---------------

**Step:** Generate a single sample from a standard normal distribution
of size *N* = 200. Explain to the reader how you use MLE to estimate the
distribution.

**Step:** Show the reader how you approximate the sampling distribution
of the median, conditional on the estimate of the distribution in the
previous step.

**Step:** Describe how you calculate a 95% confidence interval from the
approximated sampling distribution.

**Step:** Explain the concept of coverage probability. Explain your code
for calculating the coverage probability.

**Step:** Perform the simulation and report the results.

**Step:** Describe how you might change the simulation to learn more
about the operating characteristics of your chosen method for
constructing the 95% confidence interval.
