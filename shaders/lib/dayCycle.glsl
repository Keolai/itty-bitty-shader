float dayOrNight(float time){
  float dayNightMix = sin(time/3694.78); //1 is daytime, -1 is night time
	dayNightMix = (dayNightMix/2.0) + 0.5;
  return dayNightMix;
}

float getSunset(float time){
    float dayNightMix = abs(cos(time/3694.78)); //1 is daytime, -1 is night time
	//dayNightMix = (dayNightMix/2.0) + 0.5;
  return dayNightMix;
}