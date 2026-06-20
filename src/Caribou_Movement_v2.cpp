
#include <RcppArmadillo.h>
#include <RcppParallel.h>
#include <RcppArmadilloExtensions/sample.h>

// [[Rcpp::depends(RcppParallel)]]
// [[Rcpp::depends(RcppArmadillo)]]

using namespace Rcpp;
using namespace RcppParallel;
using namespace arma;

/////////////////////////////////////////////////////
///////Create helper functions//////
///////////////////////////////////////////////////

////orientation:
//given three points p, i and q, function identifies whether point i is counterclockwise to the line between points p and q
//uses determinant to do this-- if determinant is negative, point i is counterclockwise (0=on line, positive=clockwise).
//used in Jarvis March algorithm to determine convex hull.
//input p, i and q are all numeric matrices with one row and two cols made of x/y coordinates
int orientation(arma::mat p,
                arma::mat i,
                arma::mat q){ //p, i, q
int is_counterclockwise;
double det = (q(0,0)-p(0,0))*(i(0,1)-p(0,1))-(q(0,1)-p(0,1))*(i(0,0)-p(0,0));
if(det<0){
is_counterclockwise = 1;
} else{
is_counterclockwise = 0;
}

return(is_counterclockwise);
}

//match orientation
//given points p1,p2 and r1,r2...
//do p1 and p2 lie on opposite sides of line segment r1-r2?
//ie, do they intersect
int lineseg_intersect(
                arma::mat p1,
                arma::mat p2,
                arma::mat r1,
                arma::mat r2){ 

int p1_orientation;
p1_orientation=orientation(r1,p1,r2);

int p2_orientation;
p2_orientation=orientation(r1,p2,r2);                

int intersects;
if(p1_orientation==p2_orientation){
intersects=0;
} else{
intersects=1;
}

return(intersects);
}

//def do_boxes_intersect_2d(a, b):
//    # Check for separation along the X or Y axis
//    if a['xmax'] < b['xmin'] or b['xmax'] < a['xmin']:
//        return False
//    if a['ymax'] < b['ymin'] or b['ymax'] < a['ymin']:
//        return False
//    return True
int do_boxes_intersect(
                arma::mat p1,
                arma::mat p2,
                arma::mat r1,
                arma::mat r2){ 

    int boxes_intersect;

    arma::mat px = {{p1(0,0),p2(0,0)}};
    arma::mat rx = {{r1(0,0),r2(0,0)}};
    arma::mat py = {{p1(0,1),p2(0,1)}};
    arma::mat ry = {{r1(0,1),r2(0,1)}};
                
                boxes_intersect=1;

                if(px.max() < rx.min() | rx.max() < px.min()){
                  boxes_intersect=0;
                }

                if(py.max() < ry.min() | ry.max() < py.min()){
                  boxes_intersect=0;
                }
  
                return(boxes_intersect);
                }

/////////////////////////////////////////////////////
///////Set up wrapper to run with RcppParallel//////
///////////////////////////////////////////////////

//this wrapper makes the function available to RcppParallel
//the function that you want made parallel goes here in void operator
struct MoveLoop : public Worker {
  // input matrices
  const RMatrix<double> apop;
  const RMatrix<int> apopmat;
  const RMatrix<int> apoplocs;
  const RMatrix<double> acent;
  const RMatrix<double> road;
  const int pref;
  const int cent_col;
  const double inc;
  
  // output matrix
  RMatrix<double> outpop;
  
  // initialize with input and output
  //kind of like calling the function with a header, but with slightly different format
  
  //apop- whole matrix
  //apopmat- behavioral state column
  //apoplocs- current locations
  //acent- centroids matrix

  //Note: currently, apopmat and apoplocs are not used for anything. 
  //Leaving in for now because it could be a good way to feed a switch in behavioral state in this function between migr/non-migr.
  
  MoveLoop(const NumericMatrix& apop,
           const IntegerMatrix& apopmat,
           const IntegerMatrix& apoplocs,
           const NumericMatrix& acent,
           const NumericMatrix& road,
           const int pref,
           const int cent_col,
           const double inc,
           NumericMatrix outpop) 
    : apop(apop), apopmat(apopmat), apoplocs(apoplocs), acent(acent), road(road), pref(pref), cent_col(cent_col), inc(inc), outpop(outpop) {}
  
  //Below conversion funcs are in place because we need them read in as NumericMatrix/IntegerMatrix format
  //this is native format for Rcpp, and plays well with RcppParallel
  //However, arma formats speeds up simulations considerably
  //Reading them in as NumericMatrix/IntegerMatrix and converting them made it work
  arma::mat convertpop()
  {
    RMatrix<double> tmp_mat = apop;
    const arma::mat apop2(tmp_mat.begin(), tmp_mat.nrow(), tmp_mat.ncol(), false);
    return apop2;
  }
  
  arma::mat convertcent()
  {
    RMatrix<double> tmp_mat = acent;
    const arma::mat acent2(tmp_mat.begin(), tmp_mat.nrow(), tmp_mat.ncol(), false);
    return acent2;
  }
  
  arma::imat convertapopmat()
  {
    RMatrix<int> tmp_mat = apopmat;
    const arma::imat apopmat2(tmp_mat.begin(), tmp_mat.nrow(), tmp_mat.ncol(), false);
    return apopmat2;
  }
  
  arma::imat convertapoplocs()
  {
    RMatrix<int> tmp_mat = apoplocs;
    const arma::imat apoplocs2(tmp_mat.begin(), tmp_mat.nrow(), tmp_mat.ncol(), false);
    return apoplocs2;
  }

  arma::mat convertroad()
  {
    RMatrix<double> tmp_mat = road;
    const arma::mat road2(tmp_mat.begin(), tmp_mat.nrow(), tmp_mat.ncol(), false);
    return road2;
  }
  
  ///////////////////////////////////////////////////////////////////////
  /////// Parallelized loop through population matrix starts here //////
  /////////////////////////////////////////////////////////////////////
  
  
  void operator()(std::size_t begin, std::size_t end) {
    arma::mat apop3 = convertpop();
    arma::imat apopmat3 = convertapopmat();
    arma::imat apoplocs3 = convertapoplocs();
    arma::mat acent3 = convertcent();
    arma::mat road3 = convertroad();
    arma::mat diff(acent.nrow(),1);
    
    //loop through j rows of pop matrix
    for(std::size_t j = begin; j < end; j++) {
      
      //get pointers for centroids matrix
      double* cent_x = acent3.colptr(0);
      double* cent_y = acent3.colptr(1);
      
      //initialize doubles for movement distance and abundance
      //slightly faster than grabbing the numbers each time
      double pop_j_3=apop3(j,3); //distancem pop[,4]
      int pop_j_0=apop3(j,0); //abundance, pop[,1] 
      
      //loop through each element in centroids to get distance, then take the difference between that and assigned movement distance (pop_j_3)
      //if abundance (pop_j_0) and distance (pop_j_3) are greater than zero
      if(pop_j_3 > 0 & pop_j_0 > 0){
        //initialize distance matrix mask...
        arma::vec mask(diff.n_rows);
        
        double diffk_0; //initialize diffk_0 double
        
        //loop through each cell in centroids (acent3)
        for(std::size_t k = 0; k < acent.nrow(); k++) {
          //get distance between current individual and each cell in centroids, using spatial distance function
          //get difference between that and assigned movement distance
          diffk_0=abs(sqrt(pow((cent_x[k]-apop3(j,4)),2)+pow((cent_y[k]-apop3(j,5)),2))-apop3(j,3));
          

          //assign difference between assigned and actual distance to diff matrix
          diff(k,0)=diffk_0;
          
          //find distances closest to assigned movement distance, set mask to isolate those
          if(diffk_0>=0 & diffk_0<=inc){
          
          //initialize current step
          double p1_x=apop3(j,4);
          double p1_y=apop3(j,5);
          arma::mat p1(1,2);
          p1(0,0) = p1_x;
          p1(0,1) = p1_y;

          //initialize next step being considered
          double p2_x=cent_x[k];
          double p2_y=cent_y[k];
          arma::mat p2(1,2);
          p2(0,0) = p2_x;
          p2(0,1) = p2_y;
          //Rcout << "p2" << p2; 
          arma::mat r1 = arma::conv_to<arma::mat>::from(arma::rowvec(road3.row(0)));
          arma::mat r2 = arma::conv_to<arma::mat>::from(arma::rowvec(road3.row(1)));
          

          int bbox_intersects = do_boxes_intersect(p1,p2,r1,r2);

          if(bbox_intersects==1){
          
          int intersects = lineseg_intersect(p1,p2,r1,r2);
          //Rcout << "intersects" << intersects; 
          
          if(intersects==1){
            ///Rcout << "intersects";
            mask[k]=0;
          } else{
            mask[k]=1;
          }

        } else{ //bbox intersect closing bracket
          //if bbox doesn't intersect, lines cant intersect
          //this means the move is valid, doesn't cross a road
          mask[k]=1; 
        } 

          } else {
            mask[k]=0;    
          }
          
        } //going through centroids closing bracket
        
        //get the indices for set of selected cells with distance near the assigned movement distance (within 0.4)
        arma::uvec set = find(mask==1);
        
        //get size of set
        const int setsize = set.n_elem;
        //Rcout << "The value of setsize : " << setsize << "\n";


        //if some possible cells to move to... start next selection process
        
        if(setsize>0){
          
          //initialize truemin-- selected cellnumber to move to
          arma::uvec truemin;

          ////////////////////////////////////////////////////////////
          /////// Determine movement type from behavioral state /////
          //////////////////////////////////////////////////////////

          ///int behav_stat = apop3(j,6);
          
          ///////////////////////////////////////
          /////// Distance-based movement //////
          /////////////////////////////////////
          //Note: turning off this switch for now

          //This is default-- if no other options selected (i.e., abundance or rsf), movement is determined by distance alone
          
          //if pref ==0 (distance-only), randomly sample a cell in set
          //if(pref==0){
            
          //  truemin = Rcpp::RcppArmadillo::sample(set,1,false);
          //}

          //////////////////////////////////////////////////////////////////////////////
          /////// Set something to remove cells from set that result in intersection with road //////
          ////////////////////////////////////////////////////////////////////////////

          //////////////////////////////////////////////////////////////////////////////
          /////// RSF-based movement, biomass input type, with behavioral switch //////
          ////////////////////////////////////////////////////////////////////////////

          //base movement based on preference for higher biomass
          //for now, just using sample map with integers. 
          //It so happens that generally,the higher integer map has higher biomass (ran some tests with Don's equations)
          //later, will want to convert the integers to maps with actual modeled biomass differences

          if(pref==1){


              //in centroids col index is where put input for switch
              arma::vec cent_rsf = arma::conv_to<arma::vec>::from(arma::colvec(acent3.col(cent_col)));
              //subset to get rsf_vals of cells in selected set
              arma::vec dist_vals = cent_rsf(set);
              //Rcout << "The value of set : " << set << "\n";
              //Rcout << "The value of dist_vals : " << dist_vals << "\n";
              //calculate total biomass of selected set
              //double total_biomass = sum(dist_vals);

              //calculate probability based on proportion of biomass out of total sum
              //invert it because otherwise further distances are higher probability
              //add small amt to zeros to avoid NA by dividing by zero
              //arma::vec biomass_probs_0 = (biomass_vals)/total_biomass;
              //arma::vec biomass_probs = 1-biomass_probs_0;
              //get minimum distance value
              double mindistvals = dist_vals.min();
              arma::ivec distmask(dist_vals.n_rows);
            
              //Return indices of set which are equal to the minimum abundance value
              for(std::size_t p = 0; p < dist_vals.n_rows; ++p){
                if(dist_vals(p)==mindistvals) distmask[p]=1; //set poplocs mask to 1 if any loc matches cell in set
                else distmask[p]=0;
              }

              arma::uvec cellindarma = set.elem(find(distmask==1));

              //if there are more than 1 cell with same minimum abundance, choose one at random
              if(cellindarma.size()>1){
                truemin = Rcpp::RcppArmadillo::sample(cellindarma,1,false);
              
              } else {
                truemin = cellindarma;
              } 
            
            

          }
          
          //////////////////////////////////////////////////////////////////
          /////// Assign chosen location after movement pref options //////
          ////////////////////////////////////////////////////////////////
          
          //set location to selected cell in set with minimum abundance
          outpop(j,0)=truemin[0]+1; //+1 is to get appropriate index
          
        } else{ //else to 'if any cells in set'
          
          //there should always be a possible cell to move to (unless barriers introduced in model)
          //currently, if no cells in set, should generate error
          //this will output unrealistic location number that can be used in R script to generate error
          outpop(j,0)=acent.nrow()+10000000;
          
        }
        
        
      } else{ //if movement distance is zero, or abundance is zero
        
        outpop(j,0)=apoplocs(j,0);
        
        
      } //else if movement distance/abundance is zero closing loop
      
    } //worker for loop
    
  } //void operator closing loop
  
}; //worker closing loop


////////////////////////////////////////////
///////Call worker to run in parallel//////
//////////////////////////////////////////

//So, above, Movement_worker derives from RcppParallel::Worker
//this is required for function objects passed to parallelFor
//Now that the worker is described above, can call the Movement_worker worker we defined

//Here's a function that calls the SquareRoot worker defined above
// [[Rcpp::export]]
NumericMatrix parallelMovementRcpp_portion(const NumericMatrix& apop,
                                           const IntegerMatrix& apopmat,
                                           const IntegerMatrix& apoplocs,
                                           const NumericMatrix acent,
                                           const NumericMatrix road,
                                           const int pref,
                                           const int cent_col,
                                           const double inc){
  
  // allocate the output matrix
  //essentially just defining the size of the output
  NumericMatrix outpop(apop.nrow(), 1);
  
  // x is input matrix defined above
  //outpop is output matrix defined above
  MoveLoop moveloop(apop,apopmat,apoplocs,acent,road,pref,cent_col,inc,outpop);
  
  // call parallelFor to do the work
  // starting from 0 to length of apop, run the squareRoot function defined above in the worker
  //parallelFor(0, x.length(), squareRoot);
  parallelFor(0,apop.nrow(),moveloop);
  
  // return the output matrix
  return outpop;
  //}
}

///////////////////////////
///////Run the thing//////
/////////////////////////

//[[Rcpp::export]]
//define the main function, MovementRcpp
NumericMatrix MovementRcppParallel(NumericMatrix& apop,
                                   IntegerMatrix& apopmat,
                                   IntegerMatrix& apoplocs,
                                   NumericMatrix& acent,
                                   NumericMatrix& road,
                                   const int pref,
                                   const int cent_col,
                                   const double inc) {
  
  //define the main function, MovementRcpp
  
  Rcpp::NumericMatrix popout = apop;
  
  //set present locations to previous locations
  popout(_,6)=popout(_,2);
  
  //get new locations using parallel movement function
  popout(_,2)=parallelMovementRcpp_portion(apop,apopmat,apoplocs,acent,road,pref,cent_col,inc);
  
  
  return popout;
  
}