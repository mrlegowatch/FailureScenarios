#include <stdio.h>
#include "readiness.h"

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

int main(void)
{
    double restingHR, baselineHR, sleepHours, targetSleepHours, workoutLoad, soreness;

    printf("Resting HR (bpm):          "); scanf("%lf", &restingHR);
    printf("Baseline HR (bpm):         "); scanf("%lf", &baselineHR);
    printf("Sleep last night (hours):  "); scanf("%lf", &sleepHours);
    printf("Target sleep (hours):      "); scanf("%lf", &targetSleepHours);
    printf("Workout load (0-10):       "); scanf("%lf", &workoutLoad);
    printf("Soreness (0-10):           "); scanf("%lf", &soreness);

    ReadinessResult result;
    compute_readiness(restingHR, baselineHR, sleepHours, targetSleepHours,
                      workoutLoad, soreness, &result);

    printf("\nScore:           %.3f\n", result.score);
    printf("Limiting factor: %s\n", limiting_label(result.limitingFactor));

    return 0;
}
