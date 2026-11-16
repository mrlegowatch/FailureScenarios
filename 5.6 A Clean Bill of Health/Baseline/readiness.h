#ifndef READINESS_H
#define READINESS_H

/* Codes identifying which input most reduced the readiness score. */
typedef enum {
    LIMITING_NONE         = 0,
    LIMITING_RESTING_HR   = 1,
    LIMITING_SLEEP        = 2,
    LIMITING_WORKOUT_LOAD = 3,
    LIMITING_SORENESS     = 4
} LimitingFactor;

typedef struct {
    double score;          /* Composite score in [0.0, 1.0] */
    int    limitingFactor; /* LimitingFactor code */
} ReadinessResult;

/*
 * Compute a readiness score from the supplied inputs.
 *
 * restingHR        - today's resting heart rate (bpm)
 * baselineHR       - personal baseline resting heart rate (bpm)
 * sleepHours       - hours of sleep last night
 * targetSleepHours - personal target sleep duration (hours)
 * workoutLoad      - recent workout load on a [0, 10] scale
 * soreness         - muscle soreness on a [0, 10] scale
 * result           - caller-supplied struct; score and limitingFactor are written here
 */
void compute_readiness(double restingHR,
                       double baselineHR,
                       double sleepHours,
                       double targetSleepHours,
                       double workoutLoad,
                       double soreness,
                       ReadinessResult *result);

#endif /* READINESS_H */
