#define SUNRISE 23215
#define SUNSET 12785
#define MAX_TIME 23999

float dayOrNight(float time){
  float dayNightMix = sin(time/3694.78); //1 is daytime, -1 is night time
	dayNightMix = (dayNightMix/2.0) + 0.5;
  return dayNightMix;
}

float getSunset(float time){
    float dayNightMix = abs(cos(time/3694.78)); //1 is daytime, -1 is night time
    float distanceFromSunrise = min(abs(SUNRISE - time),abs((MAX_TIME - SUNRISE) - time))/(MAX_TIME/2); //check if it has gone
    float distanceFromSunset = abs(SUNSET - time)/(MAX_TIME/2);

	//dayNightMix = (dayNightMix/2.0) + 0.5;
    return 1. - min(distanceFromSunrise,distanceFromSunset);
 // return dayNightMix;
}