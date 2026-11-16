# Review of Assignment 4 - Task 1

**Scope:** `src/script.R`, its console output (re-run on a copy in `/tmp`, workspace untouched), `assignment04.pdf`, and the answers in `latex_src/main.tex`.
**Nothing was changed** - this file is the only addition.

## Verdict

| Task | Code | Report answer |
|------|------|---------------|
| 1a   | correct | answered - only typos |
| 1b   | correct | answered - okay, minor wording |
| 1c   | correct | answered, but very terse |
| 1d   | correct | answered - define positive class |
| 1e   | correct | numbers correct, **the required "which factors are responsible" explanation is missing** ("reason???") |
| 1f   | correct | **interpretation incomplete, and one inference is inverted** (aa is not overrepresented) |
| Task 2 (optional) | not attempted | empty section 2 - fine, it is optional |
| Reproducibility | script runs top-to-bottom from `src/`, deterministic, only `MASS` needed | all 8 tables + figure in the report match a fresh run exactly |

All numeric values in `main.tex` were compared line-by-line with a fresh run of `script.R` - **everything matches** (sizes, accuracies, all confusion matrices, threshold table, figure ranges).

---

## 1a) Data split and subsetting

**Code:** correct.
- `grepl("^train", phoneme$speaker)` works: speaker values look like `train.dr1.mcpm0.sa1`; 3340 train / 1169 test rows.
- Raw file has 259 columns (`row.names`, `x.1`-`x.256`, `g`, `speaker`); excluding `row.names` and `speaker` leaves 257 ✓.
- aa/ao subset sizes 1278 / 439 ✓.

**Report:** sizes and the "257 columns" statement are correct. Typo: `inlcude` -> include. Nothing missing.

## 1b) Logistic regression

**Code:** correct.
- `factor(g)` -> levels `aa`, `ao`, so `predict(type="response")` gives P(ao); `> 0.5 -> ao` is consistent with the factor coding ✓. Accuracies 0.9069 / 0.7563 ✓.
- Minor style: the variable `t` shadows the base R function `t()`; `thr` would be safer (not a bug here since `t()` is never called).

**Report:** observations are correct (high train accuracy, clearly lower test accuracy, gap explained by overfitting). Suggested small additions:
- Quantify the gap (0.9069 - 0.7563 = 0.15) and note that 256 predictors on 1278 samples makes overfitting plausible.
- "simple log reg" -> "binary logistic regression" (wording).
- Typos: `trehshold`, `probabilites`, `larger then` -> than.

## 1c) LDA (two classes)

**Code:** correct (MASS::lda, predictions on test). 0.8936 / 0.7859 ✓.

**Report:** "train acc decreases, test acc increases" is correct relative to 1b. Consider adding the takeaway: LDA generalizes slightly better here - the train-test gap shrinks (0.11 vs 0.15) because the shared-covariance Gaussian assumption stabilizes estimation with 256 predictors; also the test confusion matrix shows fewer errors on the ao class. Typos: `decreses`, `trest`.

## 1d) Confusion matrices (two classes)

**Code:** correct - `table(predicted = ..., actual = ...)` gives predicted = rows, actual = columns.

**Report:** the matrices match the output and the interpretation is correct, but state the positive class explicitly, otherwise TP/FP/FN/TN are ambiguous. You implicitly used **aa as positive**:
- TP = pred aa & act aa = 121 (same for both models), FN = pred ao & act aa = 55 (same).
- FP = pred aa & act ao: 52 (log reg) vs 39 (LDA); TN = pred ao & act ao: 211 vs 224.
- Only 13 of 439 test observations are classified differently (acc 0.7563 -> 0.7859), so "difference overall small" is right.
Typos: `deviatioins`, `agianst`.

## 1e) LDA on the full data set (5 classes)

**Code:** correct. 0.944 / 0.9196, matrix ✓.

**Report:** the observations you listed are correct:
- aa predicted better (recall 121/176 = 0.688 -> 129/176 = 0.733),
- ao almost unchanged (224/263 = 0.852 -> 223/263 = 0.848),
- dcl / iy / sh nearly perfect (recall 0.974 / 0.994 / 1.000).

**Missing (this is an explicit part of the task: "Which factors are primarily responsible for possible differences?"):** still "reason???". Suggested explanation (write 3-4 sentences):
1. **Much more training data** (3340 vs 1278 observations) -> more stable estimates of the class means and the pooled covariance.
2. **The 5-class problem is easier on average:** the three additional classes are almost perfectly separable (recall >= 0.97), and 86 of the 94 test errors still lie on the aa/ao boundary. The aggregate accuracy is therefore inflated relative to the hard binary task - 0.9196 vs 0.7859 is not a like-for-like comparison.
3. **Fair comparison on the same aa/ao test rows:** the full-data model reaches 0.8018 vs 0.7859 for the two-class LDA - a real but moderate improvement; aa/ao remains the dominant error source.
4. The train-test gap shrinks (0.11 -> 0.02), consistent with less overfitting due to the larger training set.

Also: `more then two` -> than, `phenomes` -> phonemes.

## 1f) Threshold study - what is still missing

**Code:** correct. Thresholds 0.1-0.9, reuse of the 1b predictions, accuracies and 9 matrices all match the console output; the plot was regenerated for 0.1-0.9.
- Minor: the comment "fixing the levels keeps the table 2x2..." is not implemented - `ifelse()` returns a plain character vector, so a row would silently disappear if a class were never predicted. Harmless for t = 0.1-0.9 (both classes always predicted), but the comment is misleading.

**Report issues:**
- **Inverted claim:** "accuracy generally can be biased if there is more aa then ao in the data" - it is the opposite. Actual counts:
  - train subset: aa 519 / ao 759 (40.6% / 59.4%)
  - test subset: aa 176 / ao 263 (40.1% / 59.9%)
  - ao is the majority class; always predicting ao already gives 59.9% test accuracy, so accuracy is biased **toward ao**, not aa.
- **"train acc best at around 0.4 -> hints at overrepresentation of aa"** - rework this. Mechanically, decreasing t predicts ao (majority) more often, which slightly inflates overall accuracy; the test optimum at t = 0.3 fits that direction, the train optimum at 0.4-0.5 does not support overrepresentation of aa at all. The safest reading: probabilities are roughly calibrated, and 0.5 is close to optimal.

**Missing interpretation (the actual question: "how much impact does it have on the results?").** Facts from your own output:
- Test accuracy range: 0.6902 (t=0.9) to 0.7699 (t=0.3) - about 8 percentage points; maximum at t = 0.3, then a slow decline, sharp drop only at t = 0.9 (29 test errors more than at 0.5).
- Train accuracy range: 0.8114 (t=0.9) to 0.9069 (t=0.4 and 0.5) - about 10 percentage points.
- The default t = 0.5 (0.7563) is within ~1.4 pp of the optimum; the fluctuations between 0.1 and 0.7 stay within ~1.4 pp of the 0.5 value, i.e. <= ~6 of 439 test observations - likely noise.
- Mechanism = pure recall trade-off between the classes: raising t flips predictions from ao to aa (correct aa predictions 90 -> 139, correct ao predictions 245 -> 164 as t goes 0.1 -> 0.9).
- Conclusion sentence: the threshold has a **moderate** impact - 0.5 is a sensible default for plain accuracy, and only extreme thresholds (0.9, and 0.1 for train) clearly degrade it; if misclassifying aa is costlier than ao (or vice versa), t should be shifted accordingly.
- Also fix: "i am not sure what to think about the test accuracy results" -> the small wiggles are within noise; only the 0.9 drop is systematic.

## Other notes

- **Placeholders left in the LaTeX:** "-> why?" / "reason???" (1e), "show aa ao counts in train and test data", "i am not sure what to think..." (1f). These notes still need to be turned into final text.
- **Bullets** in the LaTeX start with a literal "-" (no `itemize`), it renders as hyphens - cosmetic only.
- **Typos (full list):** inlcude, trehshold, probabilites, larger then, decreses, trest, deviatioins, agianst, more then (x2), phenomes, differnt, sligthly, overrpresentation.
- **Reproducibility (3 points):** script runs cleanly in a fresh R session from `src/` (relative path `../phoneme.csv`), no randomness (no seed needed), and every number claimed in the report is actually printed. Good.
- **Task 2** (optional, no points): not attempted - section 2 is empty; that is acceptable per the assignment sheet.
