#include "readiness.h"

/* Clamp value to [lo, hi]. */
static double pinComponent(double value, double lo, double hi)
{
    if (value < lo) return lo;
    if (value > hi) return hi;
    return value;
}

void compute_readiness(double restingHR,
                       double baselineHR,
                       double sleepHours,
                       double targetSleepHours,
                       double workoutLoad,
                       double soreness,
                       ReadinessResult *result)
{
    /*
     * HR component: 1.0 when restingHR <= baselineHR; falls linearly to 0.0
     * when restingHR is 20% above baseline.
     */
    double hrComponent;
    if (baselineHR > 0.0) {
        double elevation = (restingHR - baselineHR) / (0.20 * baselineHR);
        hrComponent = pinComponent(1.0 - elevation, 0.0, 1.0);
    } else {
        hrComponent = 1.0;
    }

    /*
     * Sleep component: 1.0 at or above target; falls linearly to 0.0 at 0 hours.
     */
    double sleepComponent;
    if (targetSleepHours > 0.0) {
        sleepComponent = pinComponent(sleepHours / targetSleepHours, 0.0, 1.0);
    } else {
        sleepComponent = 1.0;
    }

    /*
     * Load component: 1.0 at workoutLoad 0, falls linearly to 0.0 at 10.
     */
    double loadComponent = pinComponent(1.0 - workoutLoad / 10.0, 0.0, 1.0);

    /*
     * Soreness component: 1.0 at soreness 0, falls linearly to 0.0 at 10.
     */
    double sorenessComponent = pinComponent(1.0 - soreness / 10.0, 0.0, 1.0);

    /* Weighted composite. */
    result->score = 0.30 * hrComponent
                  + 0.30 * sleepComponent
                  + 0.20 * loadComponent
                  + 0.20 * sorenessComponent;

    /* Identify the lowest (most limiting) component. */
    double components[4] = { hrComponent, sleepComponent,
                              loadComponent, sorenessComponent };
    int    codes[4]      = { LIMITING_RESTING_HR, LIMITING_SLEEP,
                              LIMITING_WORKOUT_LOAD, LIMITING_SORENESS };

    result->limitingFactor = LIMITING_NONE;
    double minVal = 1.0;
    for (int i = 0; i < 4; i++) {
        if (components[i] < minVal) {
            minVal = components[i];
            result->limitingFactor = codes[i];
        }
    }
}
