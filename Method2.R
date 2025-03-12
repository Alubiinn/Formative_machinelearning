
library(e1071)
library(tidyr)
library(pROC) 
library(ggplot2)
library(caret)
library(corrplot)



adult_train_ohe <- read.csv("adult_train_ohe.csv", header = TRUE, stringsAsFactors = TRUE)
adult_test_ohe <- read.csv("adult_test_ohe.csv", header = TRUE, stringsAsFactors = TRUE)
#fnlwgt has no predictive power, other columns were also removed
adult_train_ohe$fnlwgt <- NULL


adult_train_ohe_whole <- read.csv("adult_train_ohe_whole.csv", header = TRUE, stringsAsFactors = TRUE)

cor_matrix <- cor(adult_train_ohe_whole, use = "complete.obs")
print(cor_matrix)


# Set a threshold for strong correlation
threshold <- 0.7

# Filter correlations above the threshold (absolute value)
strong_cor <- cor_matrix * (abs(cor_matrix) > threshold)

# Print only strong correlations
print(strong_cor)

high_cor_features <- findCorrelation(cor_matrix, cutoff = 0.7)

# Remove them
adult_train_ohe_filtered <- adult_train_ohe[, -high_cor_features]

print(head(adult_train_ohe_filtered))
#this is the same as adult_train_ohe

# Set seed for reproducibility
set.seed(123)

# Create an 80% training index
train_index <- createDataPartition(adult_train_ohe$income, p = 0.8, list = FALSE)

# Split the data
train_data <- adult_train_ohe_filtered[train_index, ]
test_data <- adult_train_ohe_filtered[-train_index, ]

# Check sizes
dim(train_data)  # Should be ~80% of the original dataset
dim(test_data)   # Should be ~20% of the original dataset

#creating a few svm models
svmfitl <- svm(income ~ ., data = train_data, kernel = "linear", cost = 10, scale = FALSE)
svmfitl2 <- svm(income ~ ., data = train_data, kernel = "linear", cost = 1, scale = FALSE, probability = TRUE) #the best one was used to create the ROC curve so needed probabilities
svmfitl3 <- svm(income ~ ., data = train_data, kernel = "linear", cost = 0.9, scale = FALSE)
svmfitl4 <- svm(income ~ ., data = train_data, kernel = "linear", cost = 1.1, scale = FALSE)
svmfitr <- svm(income ~ ., data = train_data, kernel = "radial", cost = 10, scale = FALSE)
svmfitp <- svm(income ~ ., data = train_data, kernel = "poly", cost = 10, scale = FALSE)

#making confusiopn matrices
svm_predictions <- predict(svmfitl, train_data)
conf_matrix <- table(Predicted = svm_predictions, Actual = train_data$income)
print(conf_matrix)
svm_predictions <- predict(svmfitl2, train_data)
conf_matrix <- table(Predicted = svm_predictions, Actual = train_data$income)
print(conf_matrix)
svm_predictions <- predict(svmfitl3, train_data)
conf_matrix <- table(Predicted = svm_predictions, Actual = train_data$income)
print(conf_matrix)
svm_predictions <- predict(svmfitl4, train_data)
conf_matrix <- table(Predicted = svm_predictions, Actual = train_data$income)
print(conf_matrix)
svm_predictions <- predict(svmfitr, train_data)
conf_matrix <- table(Predicted = svm_predictions, Actual = train_data$income)
print(conf_matrix)
svm_predictions <- predict(svmfitp, train_data)
conf_matrix <- table(Predicted = svm_predictions, Actual = train_data$income)
print(conf_matrix)

svm_predictions <- predict(svmfitl2, adult_test_ohe, probability = TRUE)

# Extract probability of positive class (">50K")
svm_probabilities <- attr(svm_predictions, "probabilities")[,2]

# Compute ROC curve
roc_curve <- roc(adult_test_ohe$income, svm_probabilities)

# Plot ROC curve
plot(roc_curve, col = "blue", lwd = 2, main = "SVM ROC Curve")
abline(a = 0, b = 1, lty = 2, col = "red")  # Add diagonal line

roc_data <- data.frame(
  TPR = rev(roc_curve$sensitivities),  # True Positive Rate
  FPR = rev(1 - roc_curve$specificities)  # False Positive Rate
)

# Plot
ggplot(roc_data, aes(x = FPR, y = TPR)) +
  geom_line(color = "blue", size = 1) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  labs(title = "SVM ROC Curve", x = "False Positive Rate", y = "True Positive Rate") +
  theme_minimal()


# Convert confusion matrix to a data frame
cm_df <- as.data.frame(conf_matrix)

# Plot
ggplot(cm_df, aes(Predicted, Actual, fill = Freq)) +
  geom_tile() +
  geom_text(aes(label = Freq), color = "white", size = 5) +
  scale_fill_gradient(low = "blue", high = "red") +
  labs(title = "SVM Confusion Matrix", x = "Predicted", y = "Actual") +
  theme_minimal()

# Fit the Naïve Bayes model
nb_model <- naiveBayes(income ~ ., data = train_data)

nb_predictions <- predict(nb_model, newdata = test_data)

conf_matrix <- confusionMatrix(nb_predictions, test_data$income)
print(conf_matrix)

#Find percentage of rows where 'income' is ">50K"
percentage <- mean(train_data$income == ">50K") * 100
print(paste("Percentage:", round(percentage, 2), "%"))
