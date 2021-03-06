// Defining beta shape paramters using paramter estimation from here
// http://quantdevel.com/public/CSP2017/ModelingProportionsAndProbabilities.pdf
// using 1 beta shared between both stimulus
//Includes a punishment sensitivity paramter (lamda)

data {
  int nsub; //number of participants
  int ntrials; //per stimulus
  real screamPlus[ntrials,nsub]; //scream CS+
  real screamMinus[ntrials,nsub]; //scream CS-
  real ratingsPlus[ntrials,nsub]; //rating per sub per trial 0-1
  real ratingsMinus[ntrials,nsub]; //rating per sub per trial 0-1
  real cdf_scale; // scaled 0.5 for adjusting from discrete values in beta dist. Scaled as per the ratings
}

parameters {
  real <lower=0,upper=1>alpha[nsub]; //learning rate
  real <lower=0> beta[nsub]; //calculate distribution variance.
                                          //Basically how confident they are when rating
                                          // related to uncertainty possibly?
                                          // to add 2, beta[nsub,2] and where used [p,1] or [p,2] by shape
  vector<lower=0.5-cdf_scale,upper=0.5+cdf_scale>[nsub] first;
  real <lower=0,upper=1>lambda[nsub]; //punishment sensitivity. Multiplier to the value update following scream


}

model {
  real shape1_Plus[ntrials,nsub]; //shape parameter 1 CS+
  real shape1_Minus[ntrials,nsub]; // shape parameter 1 CS-
  real shape2_Plus[ntrials,nsub]; // shape paramter 2 CS+
  real shape2_Minus[ntrials,nsub]; // shape paramter 2 CS-


  matrix[ntrials,nsub] VPlus; // value CS+
  matrix[ntrials,nsub] VMinus; // value CS-

  real deltaPlus[ntrials-1,nsub]; // prediction error for  CS+
  real deltaMinus[ntrials-1,nsub];    // prediction error for CS-



  //add generic weakly informative priors for all key parameters

  alpha ~ normal(0,1);
  beta ~ normal(0,1);
  lambda ~ normal(0,1);



  // define model

  for (p in 1:nsub){
    VPlus[1,p]=first[p]; // assume that the mid point varies like our ratings. so a range between 0.5-0.0555556 and 0.5+0.0000056
    VMinus[1,p]=first[p];


    for (t in 1:(ntrials-1)){
      deltaPlus[t,p] = screamPlus[t,p]*lambda[p]-VPlus[t,p]; // prediction error calc CS+, multiplied by punishment sensitivty
      deltaMinus[t,p] = screamMinus[t,p]*lambda[p]-VMinus[t,p]; // ditto CS-
      VPlus[t+1,p]=VPlus[t,p]+alpha[p]*deltaPlus[t,p]; // value calc CS+
      VMinus[t+1,p]=VMinus[t,p]+alpha[p]*deltaMinus[t,p]; // ditto CS-

      VPlus[t+1,p] = VPlus[t+1,p]+0.2*VMinus[t+1,p];
      VMinus[t+1,p] = VMinus[t+1,p]+0.2*VPlus[t+1,p];

      // contrain the shape paramters to avoid rounding errors making them above 1 or below 0

      print(VPlus[t+1,p]);
      print(VMinus[t+1,p]);

      if (VPlus[t+1,p] > 1) {
        VPlus[t+1,p] = 0.99999;
      }
      if (VMinus[t+1,p] > 1) {
        VMinus[t+1,p] = 0.99999;
      }

      print(VPlus[t+1,p]);
        print(VMinus[t+1,p]);



    }

    for (t in 1:ntrials){
      shape1_Plus[t,p] = VPlus[t,p] * ((VPlus[t,p] * (1-VPlus[t,p])) / beta[p]);
      shape1_Minus[t,p] = VMinus[t,p] * ((VMinus[t,p] * (1-VMinus[t,p])) / beta[p]);
      shape2_Plus[t,p] = (1-VPlus[t,p]) * ((VPlus[t,p] * (1-VPlus[t,p])) / beta[p]);
      shape2_Minus[t,p] = (1-VMinus[t,p]) * ((VMinus[t,p] * (1-VMinus[t,p])) / beta[p]);


      ratingsPlus[t,p] ~ beta(shape1_Plus[t,p],shape2_Plus[t,p]);
      ratingsMinus[t,p] ~ beta(shape1_Minus[t,p],shape2_Minus[t,p]);

    }
  }
}


// below is what will generate the log likelihoods.

generated quantities { //does the same calculations again for the fitted values
  real loglik[nsub];  // logliklihood paramter
  real shape1_Plus[ntrials,nsub]; //shape parameter 1 CS+
  real shape1_Minus[ntrials,nsub]; // shape parameter 1 CS-
  real shape2_Plus[ntrials,nsub]; // shape paramter 2 CS+
  real shape2_Minus[ntrials,nsub]; // shape paramter 2 CS-


  matrix[ntrials,nsub] VPlus; // value CS+
  matrix[ntrials,nsub] VMinus; // value CS-

  real deltaPlus[ntrials-1,nsub]; // prediction error for  CS+
  real deltaMinus[ntrials-1,nsub];    // prediction error for CS-


  // define model

  for (p in 1:nsub){
    VPlus[1,p]=first[p]; // assume that the mid point varies like our ratings. so a range between 0.5-0.0555556 and 0.5+0.0000056
    VMinus[1,p]=first[p];

    for (t in 1:(ntrials-1)){
      deltaPlus[t,p] = screamPlus[t,p]*lambda[p]-VPlus[t,p]; // prediction error calc CS+, multiplied by punishment sensitivty
      deltaMinus[t,p] = screamMinus[t,p]*lambda[p]-VMinus[t,p]; // ditto CS-
      VPlus[t+1,p]=VPlus[t,p]+alpha[p]*deltaPlus[t,p]; // value calc CS+
      VMinus[t+1,p]=VMinus[t,p]+alpha[p]*deltaMinus[t,p]; // ditto CS-


      VPlus[t+1,p] = VPlus[t+1,p]+0.2*VMinus[t+1,p];
      VMinus[t+1,p] = VMinus[t+1,p]+0.2*VPlus[t+1,p];

      // contrain the shape paramters to avoid rounding errors making them above 1 or below 0

      if (VPlus[t+1,p] > 1) {
        VPlus[t+1,p] = 0.99999;
      }
      if (VMinus[t+1,p] > 1) {
        VMinus[t+1,p] = 0.99999;
      }

    }

    for (t in 1:ntrials){
      shape1_Plus[t,p] = VPlus[t,p] * ((VPlus[t,p] * (1-VPlus[t,p])) / beta[p]);
      shape1_Minus[t,p] = VMinus[t,p] * ((VMinus[t,p] * (1-VMinus[t,p])) / beta[p]);
      shape2_Plus[t,p] = (1-VPlus[t,p]) * ((VPlus[t,p] * (1-VPlus[t,p])) / beta[p]);
      shape2_Minus[t,p] = (1-VMinus[t,p]) * ((VMinus[t,p] * (1-VMinus[t,p])) / beta[p]);

    //  print(beta_lpdf(ratingsPlus[t,p] | shape1_Plus[t,p],shape2_Plus[t,p]))

      // increments the log likelihood trial by trial using the log choice prob and parameters estimated in the model block
      loglik[p] += log(beta_cdf((ratingsPlus[t,p] + cdf_scale) , shape1_Plus[t,p],shape2_Plus[t,p]) -
      beta_cdf((ratingsPlus[t,p] - cdf_scale) , shape1_Plus[t,p],shape2_Plus[t,p])) +
      log(beta_cdf((ratingsMinus[t,p] + cdf_scale) , shape1_Minus[t,p],shape2_Minus[t,p]) -
      beta_cdf((ratingsMinus[t,p] - cdf_scale) , shape1_Minus[t,p],shape2_Minus[t,p]));
    }
  }
}
