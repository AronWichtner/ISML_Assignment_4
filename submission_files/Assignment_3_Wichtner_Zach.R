# The code in this script was written by Aron Wichtner and Colin Zach

# a)

# load data
phoneme <- read.csv("../phoneme.csv")

# split training and test dataset (use speaker column)
is_train <- grepl("^train", phoneme$speaker)
train <- phoneme[is_train, ]
test <- phoneme[!is_train, ]

# exlucde row number and speaker column
train <- train[, !(names(train) %in% c("row.names", "speaker"))]
test <- test[, !(names(test) %in% c("row.names", "speaker"))]

# print sizes
cat("\nSizes of train dataset:\n")
print(dim(train))
cat("\nSizes of test dataset:\n")
print(dim(test))

# create subset of original dataset with response values aa or ao
train_subset <- train[train$g %in% c("aa", "ao"), ]
test_subset <- test[test$g %in% c("aa", "ao"), ]

# print sizes
cat("\nSizes of train dataset (subset):\n")
print(dim(train_subset))
cat("\nSizes of test dataset (subset):\n")
print(dim(test_subset))

# b)

# using factor to transform response to binary values
train_subset$g <- factor(train_subset$g)
test_subset$g  <- factor(test_subset$g)

# fit logistic regression model on train subset
glm.fits <- glm(
    g ~ .,
    family = binomial,
    data = train_subset
)

# predict response with train subset data
glm.fits.prediction_train <- predict(
    glm.fits,
    type = "response"
)

# predict response with test subset data
glm.fits.prediction_test <- predict(
    glm.fits,
    newdata = test_subset,
    type = "response"
)

# classify with threshold of 0.5
t <- 0.5
pred_train <- ifelse(glm.fits.prediction_train > t, "ao", "aa")
pred_test  <- ifelse(glm.fits.prediction_test  > t, "ao", "aa")

# report train and test accuracy
# Accuracy is the fraction of all predictions that are correct
acc_train <- mean(pred_train == train_subset$g)
acc_test  <- mean(pred_test  == test_subset$g)
cat("Train accuracy:", round(acc_train, 4), "\n")
cat("Test accuracy: ", round(acc_test, 4), "\n")

# c)

library(MASS)

# fit LDA model
lda.fit <- lda(
    g ~ .,
    data = train_subset
)

# predict response with train subset data
lda.fit.prediction_train <- predict(lda.fit)

# predict response with test subset data
lda.fit.prediction_test <- predict(lda.fit, newdata = test_subset)

# report train and test accuracy
acc_test_lda <- mean(lda.fit.prediction_test$class == test_subset$g)
acc_train_lda <- mean(lda.fit.prediction_train$class == train_subset$g)
cat("Train accuracy (lda):", round(acc_train_lda, 4), "\n")
cat("Test accuracy (lda): ", round(acc_test_lda, 4), "\n")

# d)

# confusion matix for log reg
cm_glm <- table(predicted = pred_test, actual = test_subset$g)

# confusion matrix for lda
cm_lda <- table(predicted = lda.fit.prediction_test$class, actual = test_subset$g)

cat("\nConfusion matrix (logistic regression, test):\n")
print(cm_glm)
cat("\nConfusion matrix (LDA, test):\n")
print(cm_lda)

# e)

# using factor to transform response to factor (5 classes)
train$g <- factor(train$g)
test$g  <- factor(test$g)

# fit lda model on full train dataset
lda.fit.full <- lda(
    g ~ .,
    data = train
)

# predict response with train data
lda.fit.full.prediction_train <- predict(lda.fit.full)

# predict response with test data
lda.fit.full.prediction_test <- predict(lda.fit.full, newdata = test)

# report train and test accuracy
acc_test_lda_full <- mean(lda.fit.full.prediction_test$class == test$g)
acc_train_lda_full <- mean(lda.fit.full.prediction_train$class == train$g)
cat("Train accuracy on full data (lda):", round(acc_train_lda_full, 4), "\n")
cat("Test accuracy on full data (lda): ", round(acc_test_lda_full, 4), "\n")

# confusion matrix for lda on full data
cm_lda_full <- table(predicted = lda.fit.full.prediction_test$class, actual = test$g)
cat("\nConfusion matrix on full data (LDA, test):\n")
print(cm_lda_full)

# f)

thresholds <- seq(0.1, 0.9, by = 0.1)

results <- data.frame(
    threshold = thresholds,
    acc_train = NA,
    acc_test  = NA
)
cms <- list()   # one confusion matrix per threshold (test data)

for (i in seq_along(thresholds)) {
    th <- thresholds[i]

    # fixing the levels keeps the table 2x2 even if a class is never predicted
    pred_train <- ifelse(glm.fits.prediction_train > th, "ao", "aa")
    pred_test  <- ifelse(glm.fits.prediction_test  > th, "ao", "aa")

    results$acc_train[i] <- mean(pred_train == train_subset$g)
    results$acc_test[i]  <- mean(pred_test  == test_subset$g)

    cms[[i]] <- table(predicted = pred_test, actual = test_subset$g)
    names(cms)[i] <- sprintf("t = %.1f", th)
}

cat("\nAccuracy results for test and train subset data using different thresholds:\n")
print(round(results, 4))

# graph with train and test accuracy
pdf("accuracy_vs_threshold_task1f.pdf", width = 8, height = 6)
matplot(
    results$threshold,
    results[, c("acc_train", "acc_test")],
    type = "b", pch = 16, lty = 1, col = c("blue", "red"),
    xlab = "Threshold t", ylab = "Accuracy",
    main = "Logistic regression: accuracy vs. threshold"
)
legend("bottomleft", legend = c("train", "test"),
       col = c("blue", "red"), lty = 1, pch = 16)
dev.off()

# confusion matrices for each t
for (nm in names(cms)) {
    cat("\nConfusion matrix, test,", nm, "\n")
    print(cms[[nm]])
}
