#include <cstdio>
#include "readiness.hpp"

static const char *limiting_label(int code)
{
    switch (code) {
        case LIMITING_NONE:         return "none";
        case LIMITING_RESTING_HR:   return "resting HR";
        case LIMITING_SLEEP:        return "sleep";
        case LIMITING_WORKOUT_LOAD: return "workout load";
        case LIMITING_SORENESS:     return "soreness";
        default:                    return "unknown";
    }
}

int main()
{
    double restingHR, baselineHR, sleepHours, targetSleepHours, workoutLoad, soreness;

    std::printf("Resting HR (bpm):          "); std::scanf("%lf", &restingHR);
    std::printf("Baseline HR (bpm):         "); std::scanf("%lf", &baselineHR);
    std::printf("Sleep last night (hours):  "); std::scanf("%lf", &sleepHours);
    std::printf("Target sleep (hours):      "); std::scanf("%lf", &targetSleepHours);
    std::printf("Workout load (0-10):       "); std::scanf("%lf", &workoutLoad);
    std::printf("Soreness (0-10):           "); std::scanf("%lf", &soreness);

    ReadinessResult result;
    compute_readiness(restingHR, baselineHR, sleepHours, targetSleepHours,
                      workoutLoad, soreness, &result);

    std::printf("\nScore:           %.3f\n", result.score);
    std::printf("Limiting factor: %s\n", limiting_label(result.limitingFactor));

    return 0;
}
