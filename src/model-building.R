library(here)
library(readr)
library(parallel)
library(runjags)

data_path <- "data/BurnoutPA.txt"

RN4CAST_complete <-
    read_table(
        here(data_path),
        col_types = cols(
            col_integer(),
            col_integer(),
            col_factor(),
            col_factor(),
            col_integer(),
            col_factor(),
            col_double(),
            col_double(),
            col_factor(),
            col_integer()
        )
    )

RN4CAST_complete$beds <- c(scale(RN4CAST_complete$beds))
RN4CAST_complete$we <- c(scale(RN4CAST_complete$we))
RN4CAST_complete$expe <- c(scale(RN4CAST_complete$expe))

max_chains <- 16
n_chains <- min(detectCores(), max_chains)
formula <- "pa ~ (1 | unit) + (1 | hosp)"
level_covariates <- list(c("expe", "full"), c("unitsur", "we"), c("tech", "teach", "beds"))
used_covariates <- vector(mode = "character")
better_dic_found <- TRUE
burn_in_iterations <- 4000
sample_iterations <- 10000
monitor <- c("k", "intercept", "unit_precision", "hosp_precision")
method <- "parallel"

initial_model <- template.jags(
    formula = formula,
    data = RN4CAST_complete,
    file = "JAGSmodel_unif.txt",
    precision.prior = "dunif(0.001, 1000)",
    family = "poisson",
    write.data = FALSE,
    n.chains = n_chains
)
initial_run <- run.jags(
    initial_model,
    data = RN4CAST_complete,
    burnin = burn_in_iterations,
    sample = sample_iterations,
    method = method,
    monitor = monitor
)

initial_dic <- extract.runjags(initial_run, what = "dic")
lowest_cost_so_far <- sum(initial_dic$deviance) + sum(initial_dic$penalty)
runs <- list()
dics <- list()

for (level in seq_len(length(level_covariates))) {
    unused_covariates <- level_covariates[[level]]
    while (length(unused_covariates) > 0 && better_dic_found) {
        better_dic_found <- FALSE
        costs <- vector(mode = "numeric", length = length(unused_covariates))
        for (index in seq_len(length(unused_covariates))) {
            candidate_formula <- as.formula(paste(formula, unused_covariates[index], sep = " + "))
            print(paste("Now trying", toString(candidate_formula)))
            candidate_model_file_name <- paste(paste("JAGSmodel", "unif", paste(used_covariates, sep = "", collapse = "_"), unused_covariates[index], sep = "_"), ".txt", sep = "")
            candidate_model <- template.jags(
                formula = candidate_formula,
                data = RN4CAST_complete,
                file = candidate_model_file_name,
                precision.prior = "dunif(0.001, 1000)",
                family = "poisson",
                write.data = FALSE,
                n.chains = n_chains
            )
            candidate_run <- run.jags(
                candidate_model,
                data = RN4CAST_complete,
                burnin = burn_in_iterations,
                sample = sample_iterations,
                method = method,
                monitor = monitor
            )
            candidate_dic <- extract.runjags(candidate_run, what = "dic")
            runs <- c(runs, candidate_run)
            dics <- c(dics, candidate_dic)
            costs[index] <- sum(candidate_dic$deviance) + sum(candidate_dic$penalty)
        }
        lowest_cost_index <- which.min(costs)
        lowest_cost <- costs[lowest_cost_index]
        if (lowest_cost < lowest_cost_so_far) {
            formula <- paste(formula, unused_covariates[lowest_cost_index], sep = " + ")
            print(paste("New minimal DIC for", toString(formula), "=", lowest_cost))
            used_covariates <- append(used_covariates, unused_covariates[lowest_cost_index])
            unused_covariates <- unused_covariates[-c(lowest_cost_index)]
            lowest_cost_so_far <- lowest_cost
            better_dic_found <- TRUE
        }
    }
    better_dic_found <- TRUE
}
