#ifndef READINESS_HPP
#define READINESS_HPP

enum LimitingFactor {
    LIMITING_NONE         = 0,
    LIMITING_RESTING_HR   = 1,
    LIMITING_SLEEP        = 2,
    LIMITING_WORKOUT_LOAD = 3,
    LIMITING_SORENESS     = 4
};

struct ReadinessResult {
    double score;          /* Composite score in [0.0, 1.0] */
    int    limitingFactor; /* LimitingFactor code */
};

void compute_readiness(double restingHR,
                       double baselineHR,
                       double sleepHours,
                       double targetSleepHours,
                       double workoutLoad,
                       double soreness,
                       ReadinessResult *result);

#endif /* READINESS_HPP */
