#include <stdio.h>
#include "mymath.h"
#include <math.h>
#include <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#include "commdefs.h"
#include "stimuli.h"
#include "sprotos.h"
#include <stdlib.h>


#define myseed myrnd_init
#define myrand myrnd_i

//Ali
char * VERSION_NUMBER;


int dispcounts[MAXDISPS];
static int twod = 0;
extern int option2flag;
extern double gammaval;
extern unsigned long *rndbuf;
extern int optionflag,optionflags[],testflags[];
extern Expt expt;
extern int verbose, debug;
int init_rds(Stimulus *st,  Substim *sst, float density);

/*
 * NewRds Allocate memory for a new RDS stimulus structure
 * and initializes it.
 */

Substim *NewRds(Stimulus *st, Substim *sst, Substim  *copy)
{
  Locator *pos = &st->pos;/*j*/
  char revstr[256] = "$Revision: 1.34 $";
    
  if(verbose)
    printf("New RDS\n");
  sscanf(revstr,"$Revision: %f",&st->stimversion);
  FreeStimulus(sst);
  if (pos->dotsize > 0.5) /*j fudge so that cyl and rds share common dotsize*/
    sst->dotsiz[0] = sst->dotsiz[1] = pos->dotsize;
  else
    sst->dotsiz[0] = sst->dotsiz[1] = 5;
  sst->xpos = sst->ypos = NULL;
  if(pos->density != 0)
    sst->density = pos->density;
  else
    sst->density = 20;
  if(sst->baseseed <= 0 || sst->baseseed > 1000000)
    sst->seed = sst->baseseed = 1001;
  st->correlation = 1.0;
  sst->vscale = 1.0;
  st->dlength = st->dwidth = 0;
  st->phaseangle = 0;
  if(verbose)
    printf("New RDS %d\n",sizeof(OneStim));
  if(sst->ptr == NULL)
    sst->ptr = (OneStim *) (malloc(sizeof(OneStim)));
  if(verbose)
    printf("New RDS addr %d\n",sst->ptr);
  init_rds(st,sst,sst->density);
  st->type = STIM_RDS;
  sst->type = STIM_RDS;
  return(sst);
}

Substim *NewChecker(Stimulus *st, Substim *sst, Substim  *copy)
{
  Substim *new;
  new = NewRds(st,sst, copy);
  st->type = STIM_CHECKER;
  sst->type = STIM_CHECKER;
  return(sst);
    
}
/*
 * free rds frees up the memory used by and RDS stimulus structure
 */
void free_rds(Substim *st)
{
  /*
    if(st->xpos != NULL){
    //      free(st->xpos);
    st->xpos = NULL;
    }
    if(st->ypos != NULL){
    free(st->ypos);
    st->ypos = NULL;
    }
  */
    
}


int CalcNdots(Substim *sst)
{
  int ndots;
    
  /* 
   * July 2005. Calculated number of dots required for a square patch.
   * for circles, these are still calculated, just not painted if they fall 
   * outside the circle boundary
   */
    
  if(sst->type == STIM_CHECKER)
    ndots = (sst->nw+1) * (sst->nh+1);
  else
    ndots = sst->density * 4 * sst->pos.radius[0] * sst->pos.radius[1]/(100 * sst->dotsiz[0] * sst->dotsiz[1]);
  return(ndots);
}

/*
 * init_rds initializes an RDS stimulus structure. This
 * involves allocating memory for a list of dot locations
 * long enough to produce the desired to-density, given
 * the stimulus size
 */
int init_rds(Stimulus *st,  Substim *sst, float density)
{
    
  int i,j,*p;
  double val,xval,yval,x,y,cval,cm,deg,sx,sy;
  Locator *pos = &st->pos;
  int ndots;
    
  if(sst->dotsiz[0] < 0.01)
    sst->dotsiz[0] = deg2pix(0.08);
  if(sst->dotsiz[1] < 0.01)
    sst->dotsiz[1] = deg2pix(0.08);
  if(pos->radius[0] < 0.1)
    pos->radius[0] = deg2pix(2);
  if(pos->radius[0] > 2000)
    pos->radius[0] = deg2pix(2);
  if(pos->radius[1] < 0.1)
    pos->radius[1] = deg2pix(2);
  if(pos->radius[1] > 2000)
    pos->radius[1] = deg2pix(2);
    
    
  sst->pos.radius[0] = pos->radius[0];
  sst->pos.radius[1] = pos->radius[1];
    
    
    
  if(density > 0)
    sst->density = sst->density = density;
  else if(sst->density <= 0.0)
    sst->density = sst->density = 20.0;
  /*
   * calculate actual number of dots from density
   * N.B. 25 * dotsiz * dotsiz = 100 * dotsiz/2 * dotsiz/2,
   * = area of dot
   */
  if(sst->type == STIM_CHECKER){
    sst->nw = ceil(2*pos->radius[0]/sst->dotsiz[0]);
    sst->nh = ceil(2*pos->radius[1]/sst->dotsiz[1]);
  }
  ndots = CalcNdots(sst);
  if(verbose)
    printf("New RDS %d dots %.2f %.1fx%.1f %.2fx%.2f\n",ndots,sst->density,
	   sst->pos.radius[0],sst->pos.radius[1],sst->dotsiz[0] ,sst->dotsiz[1]);
    
  if(ndots > sst->iimlen || sst->im == NULL) /* need new memory */
    {
#ifdef DEBUG
      printf("%d dots %d %d\n",ndots,sst->iim,sst->xpos);
#endif
      sst->iimlen = ndots +2;
      if(sst->iim != NULL)
	free(sst->iim);
      sst->iim = (int *)malloc(sst->iimlen * sizeof(uint64_t));
    }
  if(ndots > sst->xpl || sst->xpos == NULL) /* need new memory */
    {
      if(sst->xpos != NULL)
	free(sst->xpos);
      sst->xpl = ndots+2;
      sst->xpos = (vcoord *)malloc(sst->xpl * sizeof(vcoord));
    }
  if(ndots > sst->imblen || sst->imb == NULL) /* need new memory */
    {
      if(sst->imb != NULL)
	free(sst->imb);
      sst->imblen = ndots+2;
      sst->imb = (float *)malloc(sst->imblen * sizeof(float));
    }
  if(ndots > sst->imclen || sst->imc == NULL) /* need new memory */
    {
      if(sst->imc != NULL)
	free(sst->imc);
      sst->imclen = ndots+2;
      sst->imc = (float *)malloc(sst->imclen * sizeof(float));
    }
  if(ndots > sst->ypl || sst->ypos == NULL) /* need new memory */
    {
      if(sst->ypos != NULL)
	free(sst->ypos);
      sst->ypl = ndots+2;
      sst->ypos = (vcoord *)malloc(sst->ypl * sizeof(vcoord));
    }
    
  if(ndots > 0)
    sst->ndots = ndots;
  else if(sst->ndots > 10000)
    sst->ndots = 0;
  if(!optionflags[RANDOM_DEPTH_PHASE] || expt.vals[DISTRIBUTION_WIDTH] < 2)
    st->ndisps = 0;
  st->pos.locn[0] = 0;
    
  pos->phase = 0;
    
  /*
   * some things should not be reset if we are just changing the # dots
   * only if this is the first time st-> is an RDS
   */
  if(st->lasttype != STIM_RDS){
    st->phasedisp[0] = 0;
    st->lasttype = st->type;
  }
  if(st->correlation < 1 && st->correlation > -1)
    sst->corrdots = sst->ndots * fabsf(st->correlation);
  else
    sst->corrdots = sst->ndots * 2;
  p = sst->iim;
  sst->seed = sst->baseseed;
  myseed(sst->baseseed);
  for(i = 0; i < sst->ndots; i++)
    *p++ = myrand();
  for(i = 0; i < 2; i++)
    {
      if(pos->imsize[i] == 0)
	pos->imsize[i] = 256;
      if(st->pos.radius[i] ==0)
	st->pos.radius[i] = st->pos.imsize[i]/2;
    }
  sst->xshift = 0;
  memcpy(&sst->pos,&st->pos,sizeof(Locator));
  glShadeModel(GL_FLAT);
  return(0);
}

void PrintRDSDispCounts(FILE *ofd)
{
  int i;
  if(ofd && expt.st->type == STIM_RDS){
    fprintf(ofd,"#Dots%d Disps:",expt.st->left->ndots);
    for(i = 0; i < expt.st->ndisps; i++)
      fprintf(ofd,"%d,",dispcounts[i]);
    fprintf(ofd,"\n");
  }
}

#define PIXM 10

int precalc_rds_disps(Stimulus *st)
{
  int i,j,balenced = 1;
  float *pf,*rpf,xpixdisps[MAXDISPS],ratio,pixdisp[2],phase;
//Ali did this 7/19/13
    uint64_t rnd, myrnd_u(),q;
  Locator *pos = &st->left->pos;
  Substim *sst = st->left;
  int pixmul;
  double sina,dscale;
  float *pdisp,*pdispr;
  int dotrpt = st->dotrpt;
    
  for(i = 0; i < MAXDISPS; i++)
    dispcounts[i] = 0;
    
  sina = sin(pos->angle);
  if(fabs(sina) > 0.1)
    dscale = -1/sina;
  else
    dscale = 1;
    
  myrnd_init(sst->baseseed);
  if(st->ndisps < 2)
    return(0);
  if(expt.stimmode <= DOTDIST_RANDOM)
    st->dotdist = expt.stimmode;
  else
    st->dotdist = DOTDIST_BALENCED;
  if(optionflag & ANTIALIAS_BIT)
    pixmul = PIXM;
  else
    pixmul = 1;
    
  phase = -(deg2pix(1/st->f) * st->phasedisp[0]/(2 * M_PI));
  pixdisp[0] = phase;
  if(st->mixdots < 0)
    st->mixdots = 0;
  if(st->mixdots > st->left->ndots)
    st->mixdots = st->left->ndots;
    
  for(i = 0; i < st->ndisps; i++){
    xpixdisps[i] = st->disps[i] * dscale;
  }
    
  /*
   */
    
  pf = st->left->imb;
  rpf = st->right->imb;
  for(i = 0; i < st->mixdots; i++,pf++,rpf++){
    if(st->dotdist == DOTDIST_BALENCED){
      j = i % st->ndisps;
    }
    else if(i%dotrpt == 0){
      rnd = myrnd_u();
      j = (rnd & 0xffff) % st->ndisps;
    }
    if(st->dotdist != DOTDIST_RANDOM)
      dispcounts[j]++;
    *pf = xpixdisps[j];
    *rpf = -xpixdisps[j];
  }
  for(; i < st->left->ndots; i++,pf++,rpf++)
    {
      *pf = pixdisp[0];
      *rpf = -pixdisp[0];
    }
}

/*
 * calc_rds calculates a new set of random x-y locations for the
 * dots, and randomizes them to BLACK/WHITE if required
 */
int calc_rds(Stimulus *st, Substim *sst)
{
  int i,j,partdisp,ndots;
  float cval,f,sy,cm,deg,iscale[2],val[2];
  float asq,bsq,csq,dsq,xsq,ysq,pixdisp[2],offset[2],eshift[0];
  float dpos[2],htest;
  int *cend,yi,rnd,*pl,*p;
  vcoord *x,*y,w,h,xmv[2],truex,truey,dx,dy;
  float *pdisp;
  int iw,ih,xdisp[2];
  float xshift[2];
  int ndisps;
  Locator *pos = &sst->pos;
  float phase,contrast = pos->contrast;
  int pixmul = 1,seedcall = 0;
  vcoord yp,diff;
  vcoord xpixdisps[MAXDISPS+1],xd;
  int kill_dot = 0,ncalls = 0;
  double drnd,cosa,sina,vscale,hscale,ascale,bscale,dscale;
  int eyemode,induced = 0,hpixmul,wpixmul;
  float *pf,wscale,hiscale,dw,laps,partlap,ftmp;
  int wrapped = 0,sumwrap = 0,nowrap = 1;
    int jumpdots = 0,jumpsize=1,seedoffset=0;
    
//Ali did this 7/19/13
    uint64_t q,prnd, rnds[10],myrnd_u();

    int overlap = 1,k =0, checkoverlap = 0;
  int nwrap = 5,nac=0,npaint,flipac;
    uint64_t newp = 0;
  if(st->corrmix > 0)
    checkoverlap = 0.5;
    
  nowrap = !(st->flag & RDS_WRAP);
  eyemode = sst->mode;
  if(st->flag & ANTICORRELATE && sst->mode == RIGHTMODE)
    contrast = -pos->contrast;
  if(st->flag & CONTRAST_NEGATIVE)
    val[0] = (double)st->background * (1 - contrast);
  else if(contrast >= 1.0)
    val[0]  = 1.0;
  else if(st->background == 0)
    val[0] = contrast;
  else
    val[0] = (double)st->background * (1 + contrast);
    
  if(!optionflags[RANDOM_DEPTH_PHASE] || expt.vals[DISTRIBUTION_WIDTH] < 2)
    st->ndisps = 0;
    newp = random_l();
    
  if(st->flag & CONTRAST_POSITIVE)
    {
      if(contrast >= 1.0)
	val[1]  = 1.0;
      else
	val[1] = (float)st->background * (1 + contrast);
    }
  else
    val[1] = val[0];
  for(i = 0; i < 2; i++)
    sst->lum[i] = dogamma(val[i]);
    
  /*
    if(testflags[TEST_RC] && (st->flag & UNCORRELATE))
    sst->lum[0] = sst->lum[1] = 0;
  */
  if(testflags[TEST_RC] && (fabs(st->disp+4) < 0.5 || (st->flag & UNCORRELATE)))
    sst->lum[0] = sst->lum[1] = 0;
    
  offset[0] = offset[1] = 0;
  if(sst->mode == RIGHTMODE){
    xmv[0] = pos->xy[0]-st->disp;
    xmv[1] = pos->xy[1]-st->vdisp;
    if(expt.mon->trapscale[0] > 0 && expt.mon->trapscale[0] < 2)
      vscale = expt.mon->trapscale[0];
    else
      vscale = 0;
    vscale = expt.mon->trapscale[0];
    ascale = expt.mon->trapscale[4];
    bscale = expt.mon->trapscale[6];
    if((hscale = expt.mon->trapscale[2]) == 0){
      hscale = 1.0;
      ascale = 1.0;
      bscale = 1.0;
    }
  }
  else{
    xmv[0] = pos->xy[0]+st->disp;
    xmv[1] = pos->xy[1]+st->vdisp;
    if(expt.mon->trapscale[1] > 0 && expt.mon->trapscale[1] < 2)
      vscale = expt.mon->trapscale[1];
    else
      vscale = 0;
    ascale = expt.mon->trapscale[5];
    bscale = expt.mon->trapscale[7];
    if((hscale = expt.mon->trapscale[3]) == 0){
      hscale = 1.0;
      ascale = 1.0;
      bscale = 1.0;
    }
  }
    
  cosa = cos(pos->angle);
  sina = sin(pos->angle);
  if (fabs(sina) > 0.1)
    dscale = -1/sina;
  else
    dscale = 1;
    
    
  ndots = CalcNdots(sst);
  if(ndots > sst->ndots)
    init_rds(st,sst,sst->density);
  sst->ndots = ndots;
  /* 
   *if st->prev != NULL, this is a stimuls that forms a background 
   * that means a ``hole'', with an appropriate disparity, needs to
   * be made in the background
   */
  offset[0] = offset[1] = 0;
  if(st->prev != NULL)
    {
      if(optionflag & BACKGROUND_FIXED_BIT)
        {
	  dpos[0] = st->prev->pos.xy[0] - st->pos.xy[0];
	  dpos[1] = st->prev->pos.xy[1] - st->pos.xy[1];
	  dpos[0] = st->pos.xy[0] - st->prev->pos.xy[0];
	  dpos[1] = st->pos.xy[1] - st->prev->pos.xy[1];
	  offset[0] = dpos[0] * cos(pos->angle) + dpos[1] * sin(pos->angle);
	  offset[1] = dpos[1] * cos(pos->angle) - dpos[0] * sin(pos->angle);
        }
      pixdisp[0] = (st->prev->disp - st->disp) * cos(pos->angle) +
        (st->prev->vdisp - st->vdisp) * sin(pos->angle);
      pixdisp[1] = (st->disp - st->prev->disp) * sin(pos->angle) +
        (st->prev->vdisp - st->vdisp) * cos(pos->angle);
      /*
	offset[0] += pixdisp[0];
	offset[1] += pixdisp[1];
      */
    }
  else
    {
      pixdisp[0] = pixdisp[1] = 0;
    }
  xd = xdisp[0] = xdisp[1] = 0;
    
  if(sst->seedloop == 1)
    {
      /*
       * this gives the right "TF, and gives the right
       * response to manual phase settings of +- PI, but
       * seems wrong!
       * N.B. minus sign at front gives same direction of motion for
       * sine/rds
       * Dec 2000 changed so that TF does not control speed, allows speed
       * to be matched to a sinewave
       */
      phase = -(pos->radius[1]*2 - sst->dotsiz[1]) * pos->phase/( 2 * M_PI);
      phase = -(deg2pix(1/st->f) * pos->phase/(2 * M_PI)+pos->locn[0]);
        
        
    }
  else
    phase = 0;
    
  /*
   * pos->phase is needed in this calulation even though it is not used
   * to drift the dots any more. It is used to apply "phase disparity"
   * (a wrap around rather than displacement
   */
  phase = -(pos->radius[1]*2 - sst->dotsiz[1]) * pos->phase/( 2 * M_PI);
  phase = -(deg2pix(1/st->f) * pos->phase/(2 * M_PI)+pos->locn[0]);
    
    
    
  if(optionflag & ANTIALIAS_BIT)
    pixmul = PIXM;
  else
    pixmul = 1;
  //   pixmul = 1;
    
  if(sst->xshift != 0)
    {
      xshift[0] = sst->xshift * cos(pos->angle)/pixmul;
      xshift[1] = sst->xshift * sin(pos->angle)/pixmul;
      /*
       * don't want this now xshift is used for 
       * drifting the RDS
       if(sst->seed & 1)
       {
       xshift[0] = -xshift[0];
       xshift[1] = -xshift[1];
       }
      */
      xshift[1] += phase;
      while(xshift[0] > iw)
	xshift[0] -= iw;
      while(xshift[0] < 0)
	xshift[0] += iw;
    }
  else
    {
      xshift[1] = phase * cos(st->phaseangle);
      xshift[0] = phase * sin(st->phaseangle);
    }
  csq = dsq= 0;
  w = (vcoord)(pos->imsize[0] - sst->dotsiz[0]);
  h = (vcoord)(pos->imsize[1] - sst->dotsiz[1]);
  w = (vcoord)(2 * pos->radius[0] - sst->dotsiz[0]/2);
  h = (vcoord)(2 * pos->radius[1] - sst->dotsiz[1]/2);
  dw = sst->dotsiz[0]/2;
  xshift[0] -= w/2;
    jumpdots = 2 * sst->ndots;
    jumpsize = 1;
    if (sst->seedloop > 0 && sst->ptr->deathchance > 0.001){
        jumpdots = st->framectr * sst->ndots * sst->ptr->deathchance;
        jumpdots = sst->ndots - jumpdots;
        while (jumpdots < 0){
            jumpdots += sst->ndots;
            seedoffset++;
        }
    }
    
    
    
  srandom(sst->seed+seedoffset);
  myseed(sst->seed+seedoffset);
  srand48(sst->seed+seedoffset);
  if(!(optionflag & SQUARE_RDS))
    {
      asq = pos->radius[0] * pos->radius[0];
      bsq = pos->radius[1] * pos->radius[1];
      /* calculate parameters for hole */
      if(st->prev != NULL && st->prev->type == STIM_RDS)
        {
	  csq = st->prev->pos.radius[0] * st->prev->pos.radius[0];
	  dsq = st->prev->pos.radius[1] * st->prev->pos.radius[1];
        }
      else if(st->prev != NULL && st->prev->type == STIM_ANNULUS)
        {
	  csq = (st->prev->pos.radius[0]+dw) * (st->prev->pos.radius[0]+dw);
	  dsq = (st->prev->pos.radius[1]+dw) * (st->prev->pos.radius[1]+dw);
        }
    }
  else  if(st->prev != NULL && (st->prev->type == STIM_RDS || (st->prev->type == STIM_BAR && expt.vals[ALTERNATE_STIM_MODE] > 0.5)))
        
    {
      if(st->prev->type == STIM_RDS){
	csq = fabsf(st->prev->pos.radius[0]-sst->dotsiz[0]/2);
	dsq = fabsf(st->prev->pos.radius[1]-sst->dotsiz[1]/2);
      }
      else
        {
	  csq = fabsf(st->prev->pos.radius[0]+sst->dotsiz[0]/2);
	  dsq = fabsf(st->prev->pos.radius[1]+sst->dotsiz[0]/2);
        }
    }
  p = sst->iim;
  x = sst->xpos;
  pdisp = sst->imb;
  y = sst->ypos;
  pl = sst->imc;
    
  /*
   * if the stimulus is < 1 dot wide, then dots are all in a line, but
   * don't want to /0 below!
   */
  iw = w;
  if(iw == 0)
    iw = 1;
  ih = h;
  if(ih == 0)
    ih = 1;
    
  laps = floor(fabs(xshift[1])/ih);
    
  partlap = (xshift[1]/ih)-laps;
  /*
   * years ago, xshift[1] was made a negative going quantity to get direction matched
   * with gratings etc.
   */
  while(xshift[1] > 0)
    xshift[1] -= ih;
  while(xshift[1] < -ih  && ih > 0) //negative ih if size is zero.
    xshift[1] += ih;
  seedcall = 0;
  /* now set random x,y locations */
    
  if(st->correlation < 1 && st->correlation > -1)
    sst->corrdots = sst->ndots * fabsf(st->correlation);
  else
    sst->corrdots = sst->ndots*2;
    
  /*
   * if translate whole pattern, need to subtract this from the
   * disps. Make ndisps for physiology expt only work with disp_phase,
   * and then set this to zero, but put it into xpixdisps[MAXDISP]
   */
  if(st->ndisps > 0){
    for(i = 0; i < st->ndisps; i++){
      j = i % st->ndisps;
      if(sst->mode == RIGHTMODE){
	xdisp[0] = st->disps[j];
	xpixdisps[i] = -st->disps[j] * dscale;
      }
      else{
	xdisp[0] = -st->disps[j];
	xpixdisps[i] = st->disps[j] * dscale;
      }
    }
    xpixdisps[MAXDISPS] = xshift[1];
  }
  else{
    for(i = 0; i < MAXDISPS; i++)
      xpixdisps[i] = pixdisp[0];
    xd = xshift[1];
  }
    
    
  /*
   * if ndisps > 1, means that we are doing transparent superposition of 
   * n (= st->ndisps) planes. Do this by cycling through the list of disparities
   * as we paint the dots. N.B. white/black is set at random for each dot, so 
   * these are orthogonal.
   *
   * N.B. currently only implemented for or = 90, so that xdisp[0] applies
   * horizontal disparity
   * translation of pattern done with xshift[1], which is wrapped in with pdisp here to save time
   * in the main loop.
   */
  if(st->ndisps > 1 && st->dotdist == DOTDIST_RANDOM){
    if((sst->seed % 200) <= 1){ // seeds step 2 per frame
      sst->lum[0] = sst->lum[1] = st->background;
    }
    for(i = 0; i < sst->mixdots; i++,pdisp++){
      rnd = random();
      j = rnd%st->ndisps;
      dispcounts[j]++;
      *pdisp = xpixdisps[j];
    }
    for(i = sst->mixdots; i < sst->ndots; i++,pdisp++){
      *pdisp = xshift[1];
    }
    pdisp = sst->imb;
  }
  else if(st->ndisps == 0){
    for(i = 0; i < st->left->ndots; i++,pdisp++)
      *pdisp = xshift[1];
    pdisp = sst->imb;
  }
    
  if(st->ndisps >0 &&  optionflags[TEMPORAL_GAUSS] && st->framectr < st->ndisps)
    ndisps = st->framectr+1;
  else
    ndisps = st->ndisps;
    
  yp = *y;
  if(expt.vals[ALTERNATE_STIM_MODE] == INDUCED_EFFECT ||
     expt.vals[ALTERNATE_STIM_MODE] == INDUCED_MASKED ||
     expt.vals[ALTERNATE_STIM_MODE] == INDUCED_MIMIC)
    induced = 1;
    
    
  if(sst->mode == LEFTMODE){
    eshift[0] = offset[0]-pixdisp[0];
    eshift[1] = offset[1]-pixdisp[1];
  }
  else{
    eshift[0] = offset[0]+pixdisp[0];
    eshift[1] = offset[1]+pixdisp[1];
  }
  hpixmul = ih* pixmul;
  wpixmul = iw* pixmul;
  if(sst->mixdots < 0)
    sst->mixdots = 0;
  if(sst->mixdots > sst->ndots)
    sst->mixdots = sst->ndots;
  wscale = (float)(iw)/0xffff;
  hiscale = (float)(ih)/0xffff;
    
  ncalls = 0;

  if(sst->seedloop == 1 && pos->radius[0] > pos->radius[1] * 4)
    nwrap = 32;
    nac = 0;
    npaint = 0;
    flipac = 0;
  for(i = 0; i < sst->ndots; )
    {
        
      /* 
       * make sure this only happens once. Can get stuck
       * in an infinite loop
       * with a dot SQUARE_RDS does not like
       * Also, not seed+200, not +1, otherwise R dots in
       * frame n _are_ correlated with L in frame n+1
       * Aim is if have reached number of correlated dots, throw
       * in an extra call to random to uncorrelate Right
       */
        
      if (i == jumpdots) //change remaining dots - implements deathchance
          myseed(sst->seed+jumpsize+seedoffset);
        
      if(i == sst->corrdots && sst->mode == RIGHTMODE && !seedcall){
          srandom(sst->seed+200),seedcall++;
          myseed(sst->seed+200);
      }
      prnd = myrnd_u();
      q = myrnd_u();
      if (nwrap > 15){
	rnds[0] = myrnd_u();
      }
        
      //	   *p = rndbuf[ncalls++];
        
      // ver 4.38 and earier %wpixmull means some positions more freuent
      // see rev 1.19 and earlier
      yi = (prnd>>15) & 0xffff;
        yi = q & 0xffff;
      *y = hiscale * yi + *pdisp -h/2;
        
//            q = myrnd_u();
      if(i ==0)  // track 1st dot for debugger
	*y = hiscale * yi + *pdisp -h/2;
      if(*y > h/2){
	*y -= h;
	wrapped = 1+laps;
      }
      else if(*y < -h/2){
	*y += h;
	wrapped = 1+laps;
      }
      else
	wrapped = laps;
        
      sumwrap += wrapped;
      wrapped = wrapped % nwrap; //virtual RDs nwrapx wider than windoe
      if(nowrap == 0){
	*x = wscale * (prnd & 0xffff) + xshift[0];
	wrapped = 0;
      }
      else{
	if(wrapped > 16) // kludge for now should call rand again
	  *x = wscale * ((rnds[0]>>((wrapped-16)%16)) & 0xffff) + xshift[0];
	else if(wrapped > 4) // kludge for now should call rand again
	  *x = wscale * ((q>>(wrapped%16)) & 0xffff) + xshift[0];
	else if(wrapped == 4)
	  *x = wscale * ((prnd>>32) & 0xffff) + xshift[0];
	else if(wrapped == 3)
	  *x = wscale * ((prnd>>24) & 0xffff) + xshift[0];
	else if(wrapped == 2)
	  *x = wscale * ((prnd >> 16) & 0xffff) + xshift[0];
	else if(wrapped == 1)
	  *x = wscale * ((prnd>>8) & 0xffff) + xshift[0];
	else
	  *x = wscale * ((prnd>>0) & 0xffff) + xshift[0];
      }
      if(*x > wpixmul)
	*x -= wpixmul;
        
      if(induced){
	if(expt.vals[ALTERNATE_STIM_MODE] == INDUCED_EFFECT ||
	   expt.vals[ALTERNATE_STIM_MODE] == INDUCED_MASKED){
	  *y *= sst->vscale;
	  if((*y > h/2 || *y < -h/2) && expt.vals[ALTERNATE_STIM_MODE] == INDUCED_MASKED){
	    kill_dot = 1;
	  }
	  else
	    kill_dot = 0;
	  if(expt.vals[ALTERNATE_STIM_MODE] == INDUCED_MIMIC && sst->vscale > 1){
	    drnd = mydrand();
	    htest =  1 - 2 * fabsf(*y/h) * (sst->vscale-1);
	    if (drnd >htest)
	      *x = (float)(((prnd>>8) + (int)(xshift[0]) + xdisp[0]) % (iw*pixmul))/pixmul - w/2;
	  }
	}
      }
        
      /*
       * if mixing correlations, then color of R eye dot set
       * dot by dot. corrmix 1 = all AC, 0 = all corr
       * contrast is reversed, so using same rule for L,R produces AC. 
       */
        
        flipac = 0;
      if(st->corrmix > 0 && sst->mode == RIGHTMODE)
      {
          if (npaint == 0 && (q & 255) < st->corrmix * 255)
              flipac= 1;
          else if ((float)(nac)/npaint <= st->corrmix)
              flipac = 1;
      }
      
    if((q >> 25) & 1){
        if (flipac)
            *p = BLACKMODE;
        else
          *p = WHITEMODE;
    }
    else{
        if (flipac)
            *p = WHITEMODE;
        else
          *p = BLACKMODE;
      }
        
#ifdef TESTRDS
      if(wrapped & 1)
	*p = WHITEMODE;
      else
	*p = BLACKMODE;
#endif
        
      /* 
       * if csq != 0, that means that there is an RDS pattern
       * to be painted inside this one, so be sure to leave
       * an approriate hole in the middle
       */
      if(kill_dot)
	;
      else if(csq != 0) 
        {
	  if(!(optionflag & SQUARE_RDS))
            {
	      xsq = (*x + eshift[0]) * (*x +eshift[0]);
	      ysq = (*y + eshift[1]) * (*y +eshift[1]);
                if((xsq/csq + ysq/dsq) > 1){
                    *p |= eyemode;
                    npaint++;
                    if(flipac)
                        nac++;
                }
            }
	  else
            {
	      xsq = fabsf((float)(*x + eshift[0]));
	      ysq = fabsf((float)(*y + eshift[1]));
	      if(xsq > csq || ysq > dsq)
              *p |= (eyemode);
                npaint++;
                if(flipac)
                    nac++;
            }
        }
      else /*always paint the dot */
        {
	  *p |= (RIGHTMODE | LEFTMODE);
            npaint++;
        if(flipac)
                nac++;
        }
        
        
      /* 
       * This check, for dots outside the circle
       * has to be done for both centre and surround
       */
      if(!(optionflag & SQUARE_RDS))
        { 
	  xsq = *x * *x;
	  ysq = *y * *y;
            if((xsq/asq + ysq/bsq) > 1){
          if (flipac)
              nac--;
	    *p &= (~(sst->mode));
            npaint--;
            }
        }
      /*
       * July 2005. Counter is increamented anyway, its just that the
       * dot outside elipse will not be painted
       */
      //July 2010. Code to avoid overlapping dots.
      if(checkoverlap){
	overlap = 0;
	for(k = 0; k < i && overlap == 0; k++){
	  if(fabs(sst->xpos[k]-*x) < sst->dotsiz[0] && fabs(sst->ypos[k]-*y) < sst->dotsiz[0])
	    overlap = 1;
	}
      }
      else{
	overlap = 0;
      }
        
      //	   ftmp = fabs(x[i]-x[0]);
      if(overlap == 0)
	i++,x++,y++,p++,pdisp++,pl++;
    }
  if(i > 0)
    sumwrap = sumwrap/i;
  return(ncalls);
}


void calc_rds_check(Stimulus *st, Substim *sst)
{
  int i,j,bit = 0,nw,nh,*p,dotmode;
  unsigned long rnd;
  vcoord *q;
  Locator *pos = &st->pos;
  double contrast = pos->contrast;
  double contrast2 = pos->contrast2;
  double xv[1024],yv[1024],yenv[1024],xenv[1024];
  double ysd,r,xm, cscale = 2,xsd,xdisp,val;
  double asq,bsq = 0,csq,dsq,xsq,ysq,pixdisp[2],offset[2],eh = 0;
  int disp; 
    
    
  if(st->flag & ANTICORRELATE && sst->mode == RIGHTMODE){
    contrast = -pos->contrast;
    contrast2 = -pos->contrast2;
  }
    
    
  /* if the summed contrast < 1, then the contrast is exactly that.
   * if the summ is >1, then both are scaled so that the sum is 1
   */
  cscale = fabs(contrast)+fabs(contrast2);
  cscale = cscale > 1  ? cscale : 1;
  if(expt.stimmode == ORTHOG_BLANK)
    contrast2 = 0;
    
  sst->lum[0] = contrast/cscale;
  sst->lum[1] = -contrast/cscale;
  sst->lum[2] =  contrast2/cscale;
  sst->lum[3] = -sst->lum[2];
    
    
  /*
   * disp displaces checks within the pattern, using wraparound.
   * so no need to apply to both eyes. Allows 1 "pixel" disparities
   * But NB would be a problem with sl=1 and moving disparity
   */
    
  if(sst->mode == RIGHTMODE){
    dotmode = RIGHTDOT;
    xdisp =  deg2pix(st->phasedisp[0]);
    disp = rint(xdisp/sst->dotsiz[0]);
    sst->disprem = xdisp - disp * sst->dotsiz[0];
  }
  if(sst->mode == LEFTMODE){
    dotmode = LEFTDOT;
    disp = 0;
    sst->disprem = 0;
  }
  sst->nw = ceil(2*pos->radius[0]/sst->dotsiz[0]);
  sst->nh = ceil(2*pos->radius[1]/sst->dotsiz[1]);
  sst->ndots = sst->nw * sst->nh;
  if((sst->nw+1) * (sst->nh+1) > sst->iimlen)
    init_rds(st, sst, 0);
    
  myrnd_init(sst->baseseed);
    srand48(sst->baseseed);
    rnd = myrnd_u();
    
    
  if(!(optionflag & SQUARE_RDS))
    {
      asq = pos->radius[0] * pos->radius[0];
      bsq = pos->radius[1] * pos->radius[1];
    }
    
  p = sst->iim;
  if(st->left->ptr->sx > 0.01){
    xsd = deg2pix(sst->ptr->sx)/sst->dotsiz[0];
    xsd = 2 * xsd * xsd;
  }
  else
    xsd = 0;
  if(st->left->ptr->sy > 0.01){
    ysd = deg2pix(sst->ptr->sx)/sst->dotsiz[1];
    ysd = 2 * ysd * ysd;
  }
  else
    ysd = 0;
    
  q = sst->imb;
  p = sst->iim;
  xm = sst->nw/2;
    val = fabs(st->plaid_angle - M_PI_2);
  if(fabs(st->plaid_angle - M_PI_2) < 0.01){
    bit = 1;
    if(expt.stimmode == ORTHOG_UC && sst->mode == RIGHTMODE)
      bit = 2;
    for(i = 0; i < sst->nw; i++){
      j = i+disp;
        if (j < 0)
            j = j+sst->nw;
        else if (j >= sst->nw)
            j = j-sst->nw;

        if (xsd > 0){
	r = sqr(j -xm)/xsd;
	xenv[j] = exp(-r);
      }
      else if (bsq > 0)
	xenv[j] = sqr((j-xm) * sst->dotsiz[0]);
      else
	xenv[j] = 1;
            
      if(expt.stimmode == ORTHOG_AC && sst->mode == RIGHTMODE){
	if(rnd & bit)
	  xv[j] = sst->lum[0];
	else
	  xv[j] = sst->lum[1];
      }
      else{
	if(rnd & bit)
	  xv[j] = sst->lum[0];
	else
	  xv[j] = sst->lum[1];
      }
      rnd = myrnd_u();
    }
    bit = 1;
    xm = sst->nh/2;
    for(i = 0; i < sst->nh; i++){
      if (ysd > 0){
	r = sqr(i -xm)/ysd;
	yenv[i] = exp(-r);
      }
      else if (bsq > 0)
	yenv[i] = sqr((i-xm) * sst->dotsiz[1]);
      else
	yenv[i] = 1;
      if(expt.stimmode == PARALLEL_UC && sst->mode == RIGHTMODE)
	bit = 2;
      if(expt.stimmode == PARALLEL_AC && sst->mode == RIGHTMODE){
	if(rnd & bit)
	  yv[i] = sst->lum[2];
	else
	  yv[i] = sst->lum[3];
      }
      else{
	if(rnd & bit)
	  yv[i] = sst->lum[3];
	else
	  yv[i] = sst->lum[2];
      }
      rnd = myrnd_u();
    }
    p = sst->iim;
    if(bsq > 0){
      for(i = 0; i < sst->nw; i++){
	for(j = 0; j < sst->nh; j++){
	  if(xenv[i] + yenv[j] > bsq){
	    *q = st->background;
	    *p = 0;
	  }
	  else{
	    *q = st->background+(xv[i]+yv[j])/(2);
	    *p |= (RIGHTDOT | LEFTDOT);
	  }
	  p++,q++;
	}
      }
    }
    else{
      for(i = 0; i < sst->nw; i++){
	for(j = 0; j < sst->nh; j++){
	  *q = st->background+(xv[i]+yv[j])*xenv[i]*yenv[j]/(2);
	  *p |= (RIGHTDOT | LEFTDOT);
	  q++,p++;
	}
      }
    }
  }
  else{
    for(i = 0; i < sst->nw; i++){
      for(j = 0; j < sst->nh; j++){
          
	if(bit++ > 30){
	  bit = 0;
	  rnd = myrnd_u();
	}
    val = mydrand();
    if (val > sst->density/100)
        *p = GREYMODE;
	else if(rnd & (1L<<bit))
	  *p = WHITEMODE;
	else
	  *p = BLACKMODE;
	*p |= (dotmode);
	p++;
      }
    }
  }
}


void testcalc_rds(Stimulus *st, Substim *sst, int mode)
{
  int i,j,partdisp,ndots;
  float cval,f,sy,cm,deg,iscale[2],val[2];
  float asq,bsq,csq,dsq,xsq,ysq,pixdisp[2],offset[2];
  float dpos[2],htest;
  int *p,*q,*cend,yi;
  vcoord *x,*y,w,h,xmv[2],truex,truey,dx,dy;
  int xshift[2],iw,ih,xdisp[2],xs;
  int ndisps,pixx,pixy;
  Locator *pos = &sst->pos;
  float phase,contrast = pos->contrast;
  int pixmul = 1,seedcall = 0;
  vcoord yp,diff;
  vcoord xpixdisps[MAXDISPS];
  int kill_dot = 0;
  double drnd,cosa,sina,vscale,hscale,ascale,bscale;
  int eyemode;
  float dw = sst->dotsiz[0];
    
    
  if(st->flag & ANTICORRELATE && sst->mode == RIGHTMODE)
    contrast = -pos->contrast;
  if(st->flag & CONTRAST_NEGATIVE)
    val[0] = (double)st->background * (1 - contrast);
  else if(contrast >= 1.0)
    val[0]  = 1.0;
  else if(st->background == 0)
    val[0] = contrast;
  else
    val[0] = (double)st->background * (1 + contrast);
  if(st->flag & CONTRAST_POSITIVE)
    {
      if(contrast >= 1.0)
	val[1]  = 1.0;
      else
	val[1] = (float)st->background * (1 + contrast);
    }
  else
    val[1] = val[0];
  for(i = 0; i < 2; i++)
    sst->lum[i] = dogamma(val[i]);
    
  /*
    if(testflags[TEST_RC] && (st->flag & UNCORRELATE))
    sst->lum[0] = sst->lum[1] = 0;
  */
  if(testflags[TEST_RC] && (fabs(st->disp+4) < 0.5 || (st->flag & UNCORRELATE)))
    sst->lum[0] = sst->lum[1] = 0;
    
  offset[0] = offset[1] = 0;
  if(sst->mode == RIGHTMODE){
    xmv[0] = pos->xy[0]-st->disp;
    xmv[1] = pos->xy[1]-st->vdisp;
    vscale = expt.mon->trapscale[0];
    ascale = expt.mon->trapscale[4];
    bscale = expt.mon->trapscale[6];
    if((hscale = expt.mon->trapscale[2]) == 0){
      hscale = 1.0;
      ascale = 1.0;
      bscale = 1.0;
    }
  }
  else{
    xmv[0] = pos->xy[0]+st->disp;
    xmv[1] = pos->xy[1]+st->vdisp;
    vscale = expt.mon->trapscale[1];
    ascale = expt.mon->trapscale[5];
    bscale = expt.mon->trapscale[7];
    if((hscale = expt.mon->trapscale[3]) == 0){
      hscale = 1.0;
      ascale = 1.0;
      bscale = 1.0;
    }
  }
    
  cosa = cos(pos->angle);
  sina = sin(pos->angle);
  ndots = CalcNdots(sst);
  if(mode == 3)
    ndots = 100;
  if(ndots > sst->ndots)
    init_rds(st,sst,sst->density);
  sst->ndots = ndots;
  /* 
   *if st->prev != NULL, this is a stimuls that forms a background 
   * that means a ``hole'', with an appropriate disparity, needs to
   * be made in the background
   */
  offset[0] = offset[1] = 0;
  if(st->prev != NULL)
    {
      if(optionflag & BACKGROUND_FIXED_BIT)
        {
	  dpos[0] = st->prev->pos.xy[0] - st->pos.xy[0];
	  dpos[1] = st->prev->pos.xy[1] - st->pos.xy[1];
	  dpos[0] = st->pos.xy[0] - st->prev->pos.xy[0];
	  dpos[1] = st->pos.xy[1] - st->prev->pos.xy[1];
	  offset[0] = dpos[0] * cos(pos->angle) + dpos[1] * sin(pos->angle);
	  offset[1] = dpos[1] * cos(pos->angle) - dpos[0] * sin(pos->angle);
        }
      pixdisp[0] = (st->prev->disp - st->disp) * cos(pos->angle) +
        (st->prev->vdisp - st->vdisp) * sin(pos->angle);
      pixdisp[1] = (st->disp - st->prev->disp) * sin(pos->angle) +
        (st->prev->vdisp - st->vdisp) * cos(pos->angle);
      offset[0] += pixdisp[0];
      offset[1] += pixdisp[0];
    }
  else
    {
      pixdisp[0] = pixdisp[1] = 0;
    }
  xdisp[0] = xdisp[1] = 0;
    
  if(sst->seedloop == 1)
    {
      /*
       * this gives the right "TF, and gives the right
       * response to manual phase settings of +- PI, but
       * seems wrong!
       * N.B. minus sign at front gives same direction of motion for
       * sine/rds
       * Dec 2000 changed so that TF does not control speed, allows speed
       * to be matched to a sinewave
       */
      phase = -(pos->radius[1]*2 - sst->dotsiz[1]) * pos->phase/( 2 * M_PI);
      phase = -(deg2pix(1/st->f) * pos->phase/(2 * M_PI)+pos->locn[0]);
        
        
    }
  else
    phase = 0;
    
    
  phase = -(pos->radius[1]*2 - sst->dotsiz[1]) * pos->phase/( 2 * M_PI);
  phase = -(deg2pix(1/st->f) * pos->phase/(2 * M_PI)+pos->locn[0]);
    
    
    
  if(optionflag & ANTIALIAS_BIT)
    pixmul = PIXM;
  else
    pixmul = 1;
    
  if(sst->xshift != 0)
    {
      xshift[0] = (int)(rint(sst->xshift * cos(pos->angle)));
      xshift[1] = (int)(rint(sst->xshift * sin(pos->angle)));
      /*
       * don't want this now xshift is used for 
       * drifting the RDS
       if(sst->seed & 1)
       {
       xshift[0] = -xshift[0];
       xshift[1] = -xshift[1];
       }
      */
      xshift[1] += phase;
    }
  else
    {
      xshift[1] = phase * pixmul;
      xshift[0] = 0;
    }
  csq = dsq= 0;
  w = (vcoord)(pos->imsize[0] - sst->dotsiz[0]);
  h = (vcoord)(pos->imsize[1] - sst->dotsiz[1]);
  w = (vcoord)(2 * pos->radius[0] - sst->dotsiz[0]/2);
  h = (vcoord)(2 * pos->radius[1] - sst->dotsiz[1]/2);
  myseed(sst->seed);
  srand48(sst->seed);
  if(!(optionflag & SQUARE_RDS))
    {
      asq = pos->radius[0] * pos->radius[0];
      bsq = pos->radius[1] * pos->radius[1];
      /* calculate parameters for hole */
      if(st->prev != NULL && st->prev->type == STIM_RDS)
        {
	  csq = st->prev->pos.radius[0] * st->prev->pos.radius[0];
	  dsq = st->prev->pos.radius[1] * st->prev->pos.radius[1];
        }
    }
  else  if(st->prev != NULL && (st->prev->type == STIM_RDS || (st->prev->type == STIM_BAR && expt.vals[ALTERNATE_STIM_MODE] > 0.5)))
        
    {
      if(st->prev->type == STIM_RDS){
	csq = fabsf(st->prev->pos.radius[0]-sst->dotsiz[0]/2);
	dsq = fabsf(st->prev->pos.radius[1]-sst->dotsiz[1]/2);
      }
      else
        {
	  csq = fabsf(st->prev->pos.radius[0]+sst->dotsiz[0]/2);
	  dsq = fabsf(st->prev->pos.radius[1]+sst->dotsiz[0]/2);
        }
    }
  p = sst->iim;
  x = sst->xpos;
  y = sst->ypos;
    
  /*
   * if the stimulus is < 1 dot wide, then dots are all in a line, but
   * don't want to /0 below!
   */
  iw = w;
  if(iw == 0)
    iw = 1;
  ih = h;
  if(ih == 0)
    ih = 1;
    
  seedcall = 0;
  /* now set random x,y locations */
    
  if(st->correlation < 1 && st->correlation > -1)
    sst->corrdots = sst->ndots * fabsf(st->correlation);
  else
    sst->corrdots = sst->ndots*2;
    
  if(st->ndisps > 0){
    for(i = 0; i < st->ndisps; i++){
      j = i % st->ndisps;
      if(sst->mode == RIGHTMODE)
	xdisp[0] = st->disps[j] * pixmul;
      else
	xdisp[0] = -st->disps[j] * pixmul;
      xpixdisps[i] = pixdisp[0] + st->disps[j];
    }
  }
  else{
    for(i = 0; i < MAXDISPS; i++)
      xpixdisps[i] = pixdisp[0];
  }
  if(st->ndisps >0 &&  optionflags[TEMPORAL_GAUSS] && st->framectr < st->ndisps)
    ndisps = st->framectr+1;
  else
    ndisps = st->ndisps;
    
    
  pixx = iw * pixmul;
  pixy = ih * pixmul;
  xs = xshift[0] + xdisp[0];
  for(i = 0; i < sst->ndots; i++,x++,y++,p++)
    {
      if(ndisps > 0){
	j = i % ndisps;
	if(sst->mode == RIGHTMODE)
	  xdisp[0] = st->disps[j] * pixmul;
	else
	  xdisp[0] = -st->disps[j] * pixmul;
      }
        
      //          *p = myrand();
      *p = random();
      *x = (float)((*p + xs) % pixx)/pixmul - w/2;
      yi = ((*p>>16) + xshift[1]);
      *y = (float)((yi)%(pixy))/pixmul -h/2;
        
      if(*p & 1)
	*p = WHITEMODE;
      else
	*p = BLACKMODE;
      if(mode == 3){
	*p = WHITEMODE;
	*x = i/20;
	*y = ndots/2 * dw - i * dw;
      }
        
      *p |= (RIGHTMODE | LEFTMODE);
    }
}

/*
 * this simply draws all the dots on the list, with an appropriate
 * disparity
 */
void paint_rds(Stimulus *st, int mode)
{
  int i;
  int *p,d,*end;
  vcoord  w,h,*x,*y,fw,fh,r,lw;
  short pt[2];
  float vcolor[4], bcolor[4];
  vcoord xmv;
  Substim *sst = st->left;
  Locator *pos = &st->pos;
  float angle,cosa,sina,adj=1.5;
  vcoord rect[20],crect[8];
    
    
  angle = rad_deg(pos->angle);
  /*
   * first glTranslatef the co-ordinate system to put the stimulus
   * in the right place/orientation. Use different colors for
   * L/R dots
   */
    
  glPushMatrix();
  vcolor[0] = vcolor[1] = vcolor[2] = 0;
  bcolor[0] = bcolor[1] = bcolor[2] = 0;
  if(mode == LEFTMODE)
    {
      xmv = pos->xy[0]+st->disp;
      glTranslatef(xmv,pos->xy[1]+st->vdisp,0);
      vcolor[0] = sst->lum[0];
      bcolor[0] = sst->lum[1];
    }
  else if(mode == RIGHTMODE)
    {
      sst = st->right;
      xmv = pos->xy[0]-st->disp;
      glTranslatef(xmv,pos->xy[1]-st->vdisp,0);
      vcolor[1] = vcolor[2] = sst->lum[0];
      bcolor[1] = bcolor[2] = sst->lum[1];
    }
  if(optionflags[STIMULUS_IN_OVERLAY])
    {
      vcolor[1] = vcolor[2] = vcolor[0] = sst->lum[0];
      bcolor[1] = bcolor[2] = bcolor[0] = sst->lum[1];
    }
  bcolor[3] = vcolor[3] = 1.0;
  glRotatef(angle,0.0,0.0,1.0);
    
  mycolor(vcolor);
  w = sst->dotsiz[0]/2;
  h = sst->dotsiz[1]/2;
  fw = sst->dotsiz[0];
  fh = sst->dotsiz[1];
  lw = w;
    
  cosa = cos(pos->angle);
  sina = sin(pos->angle);
#ifdef Darwin
  if(optionflag & ANTIALIAS_BIT){
    //    w = w-0.5;
    //    h = h-0.5;
  }
#endif
// Drawing and AA line around the edge effecitvely increases dot size by 1 pixel
// so adjust here.
    if(optionflag & ANTIALIAS_BIT){
        if (st->aamode == AALINE || st->aamode == AAVLINE || st->aamode == AAHLINE){ // AA is only at sides
            h = h - 0.5;
            w = w - 0.5;
            if( w < 0.5)
                w = 0.5;
            if( h < 0.5)
                h = 0.5;
            adj = 0;
        }
        else if (st->aamode == AAPOLYGON_AND_LINE){
            h = h - 0.5;
            w = w - 0.5;
        }
            
    }
    
  rect[0] = -w * cosa - h * sina; //-w,-h
  rect[1] = -h * cosa + w * sina;
  rect[2] = -w * cosa + h * sina; 
  rect[3] = h * cosa + w * sina;
  rect[4] = w * cosa + h * sina;
  rect[5] = h * cosa - w * sina;
  rect[6] = w * cosa - h * sina;
  rect[7] = -h * cosa - w * sina;
    
    rect[0] = -w * cosa - h * sina; //-w,-h
    rect[1] = -h * cosa + w * sina;
    rect[2] = -w * cosa + h * sina; //-w,h
    rect[3] = h * cosa + w * sina;
    rect[4] = w * cosa + h * sina;  //w,h
    rect[5] = h * cosa - w * sina;
    rect[6] = w * cosa - h * sina; //w,-h
    rect[7] = -h * cosa - w * sina;
    
    rect[8] = (rect[0]+rect[6])/2;
    rect[9] = (rect[1]+rect[7])/2;
    rect[10] = (rect[0]+rect[2])/2;
    rect[11] = (rect[1]+rect[3])/2;
    rect[12] = (rect[4]+rect[6])/2;
    rect[13] = (rect[5]+rect[7])/2;
    rect[14] = (rect[2]+rect[4])/2;
    rect[15] = (rect[3]+rect[5])/2;

    
  crect[0] = -h * sina;
  crect[1] = -h * cosa;
  crect[2] = h * sina;
  crect[3] = h * cosa;
    
    if (st->aamode ==4){
        rect[0] = -(w-adj) * cosa - (h-adj) * sina; //-w,-h
        rect[1] = -(h-adj) * cosa + (w-adj) * sina;
        rect[6] = (w-adj) * cosa - (h-adj) * sina;
        rect[7] = -(h-adj) * cosa - (w-adj) * sina;
    }
  h = h+0.5;
  p = sst->iim;
  end = (sst->iim+sst->ndots);
  x = sst->xpos;
  y = sst->ypos;
  i = 0;
  /* now paint the dots */
  if(sst->mode == STIM_CIRCLE)
    {
      for(;p < end; p++,x++,y++)
	mycirc(*x,*y,w);
    }
  else
    {
      if(optionflag & ANTIALIAS_BIT)
        {
            if(st->aamode == AAPOLYLINE){ //Line Blending then polygon
                glLineWidth(1.0);
                glEnable(GL_POLYGON_SMOOTH);
                glEnable(GL_LINE_SMOOTH);
                glEnable(GL_BLEND);
                glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
                glDisable(GL_DEPTH_TEST);
                glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                i = 0;
                for(;p < end; p++,x++,y++)
                {
                    if(*p & BLACKMODE)
                        mycolor(vcolor);
                    else if(*p & WHITEMODE)
                        mycolor(bcolor);
                    if(*p & mode)
                        aarotrect(rect, *x,*y);
                }

                glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
                glDisable(GL_POLYGON_SMOOTH);
                p = sst->iim;
                end = (sst->iim+sst->ndots);
                x = sst->xpos;
                y = sst->ypos;
                for(;p < end; p++,x++,y++)
                {
                    if(*p & BLACKMODE)
                        mycolor(vcolor);
                    else if(*p & WHITEMODE)
                        mycolor(bcolor);
                    if(*p & mode)
                        aarotrect(rect, *x,*y);
                }
            }
        else if(st->aamode == AAPOLYGON){ //use polygon smoothing
            glLineWidth(1.0);
            glEnable(GL_POLYGON_SMOOTH);
            glEnable(GL_LINE_SMOOTH);
            glEnable(GL_BLEND);
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
            glDisable(GL_DEPTH_TEST);
            glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            i = 0;
            for(;p < end; p++,x++,y++)
            {
                if(*p & BLACKMODE)
                    mycolor(vcolor);
                else if(*p & WHITEMODE)
                    mycolor(bcolor);
                if(*p & mode)
                    aarotrect(rect, *x,*y);
            }
        }
        else if(st->aamode == AAPOLYGON){ //use polygon smoothing
            glLineWidth(1.0);
            glEnable(GL_POLYGON_SMOOTH);
            glEnable(GL_LINE_SMOOTH);
            glEnable(GL_BLEND);
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
            glDisable(GL_DEPTH_TEST);
            glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            i = 0;
            for(;p < end; p++,x++,y++)
            {
                if(*p & BLACKMODE)
                    mycolor(vcolor);
                else if(*p & WHITEMODE)
                    mycolor(bcolor);
                if(*p & mode)
                    aarotrect(rect, *x,*y);
            }
        }
        else if(st->aamode == AAPOLYGON_AND_LINE){ //Try stuff - polygon + gl_lines so no mode change
            glLineWidth(1.0);
            glEnable(GL_LINE_SMOOTH);
            glDisable(GL_POLYGON_SMOOTH);
            glEnable(GL_BLEND);
            glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            i = 0;
            for(;p < end; p++,x++,y++)
            {
                if(*p & BLACKMODE)
                    mycolor(vcolor);      
                else if(*p & WHITEMODE)
                    mycolor(bcolor);
                if(*p & mode){
                    aarotrect(rect, *x,*y);
                }
            }
        }
        else if(st->aamode == AALINE || st->aamode == AAHLINE || st->aamode == AAVLINE){ //use thick line;
            if(lw < 0.5)
                glLineWidth(1.0);
            else
                glLineWidth(lw*2);
            glEnable(GL_LINE_SMOOTH);
            glDisable(GL_POLYGON_SMOOTH);
            glEnable(GL_BLEND);
            glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glBegin(GL_LINES);
            i = 0;
            for(;p < end; p++,x++,y++)
            {
                if(*p & BLACKMODE)
                    mycolor(vcolor);
                else if(*p & WHITEMODE)
                    mycolor(bcolor);
                if(*p & mode){
                    aarotrect(rect,*x,*y);
                }
            }
            glEnd();
        }
        
      p = sst->iim;
      x = sst->xpos;
      y = sst->ypos;
      glDisable(GL_BLEND);
      glDisable(GL_LINE_SMOOTH);
      glDisable(GL_POLYGON_SMOOTH);
        }
  else {
      if(w < 0.5)
          glLineWidth(1.0);
      else
          glLineWidth(w*2);
         glBegin(GL_LINES);
          i = 0;
          for(;p < end; p++,x++,y++)
          {
              if(*p & BLACKMODE)
                  mycolor(vcolor);      
              else if(*p & WHITEMODE)
                  mycolor(bcolor);
              if(*p & mode)
                  aarotrect(rect,*x,*y);
          }
          if(optionflag & TEST_BIT)
              rotrect(crect,expt.vals[TEST_VALUE1],expt.vals[TEST_VALUE2]);
          glEnd();
  }
    }

     glPopMatrix();
}
    



  void paint_rds_check(Stimulus *st, Substim *sst)
  {
    int *p,*end,i,j,k  = 0;
    vcoord  w,h,*x,*y,fw,fh,a[2],b[2],c[2],d[2],xmv,*q;
    float wcolor[3],bcolor[3],angle,vcolor[3],pcolor[3];
    Locator *pos = &(st->pos);
    wcolor[0] = wcolor[1] = wcolor[2] = 1.0;
    bcolor[0] = bcolor[1] = bcolor[2] = 0.0;
      pcolor[0] = pcolor[1] = pcolor[2] = 0.5;
      
    glPushMatrix();
    angle = rad_deg(pos->angle);
    if(sst->mode == LEFTMODE)
      {
	xmv = pos->xy[0]+st->disp;
	glTranslatef(xmv,pos->xy[1]+st->vdisp,0);
	wcolor[0] = 1.0;
	bcolor[0] = sst->lum[1];
      }
    else if(sst->mode == RIGHTMODE)
      {
	sst = st->right;
	xmv = pos->xy[0]-st->disp;
	glTranslatef(xmv,pos->xy[1]-st->vdisp,0);
	wcolor[1] = wcolor[2] = 1.0;
	bcolor[1] = bcolor[2] = sst->lum[1];
      }
    glRotatef(angle,0.0,0.0,1.0);
        
        
    p = sst->iim;
    fw = (sst->nw * sst->dotsiz[1])/2;
    fh = (sst->nh * sst->dotsiz[0])/2;
    if(fabs(st->plaid_angle - M_PI_2) < 0.01){
      q = sst->imb;
      for(i = 0; i < sst->nw; i++){
	glBegin(GL_QUAD_STRIP);
	if(i == 0){
	  c[1] = d[1] = (i+1) * sst->dotsiz[1] -fw+sst->disprem;
	  a[1] = b[1] = i * sst->dotsiz[1] -fw;
	}
	else if(i == sst->nw-1){
	  c[1] = d[1] = (i+1) * sst->dotsiz[1] -fw;
	  a[1] = b[1] = i * sst->dotsiz[1] -fw+sst->disprem;
	}    
	else{
	  c[1] = d[1] = (i+1) * sst->dotsiz[1] -fw+sst->disprem;
	  a[1] = b[1] = i * sst->dotsiz[1] -fw+sst->disprem;
	}
	a[0] = c[0] = 0;
	pcolor[0] = pcolor[1] = pcolor[2] = *q;
	mycolor(pcolor);
	myvx(a);
	myvx(c);
	for(j = 0; j < sst->nh; j++){
	  if(j == 0)
	    a[0] = c[0] = j * sst->dotsiz[0] -fh;
	  else
	    a[0] = c[0] = j * sst->dotsiz[0] -fh;
	  b[0] = d[0] = (j+1) * sst->dotsiz[0] -fh;
	  pcolor[0] = pcolor[1] = pcolor[2] = *q;
	  mycolor(pcolor);
	  myvx(a);
	  myvx(c);
	  q++;
	}
	glEnd();
      }
            
            
    }
    else{
            
      p = sst->iim;
      fw = (sst->nw * sst->dotsiz[1])/2;
      fh = (sst->nh * sst->dotsiz[0])/2;
      for(i = 0; i < sst->nw; i++){
	glBegin(GL_QUAD_STRIP);
	a[1] = b[1] = i * sst->dotsiz[1] -fw;
	c[1] = d[1] = (i+1) * sst->dotsiz[1] -fw;
	a[0] = c[0] = 0;
	if(*p & WHITEMODE)
	  mycolor(wcolor);
    else if(*p & GREYMODE)
        mycolor(pcolor);
	else
	  mycolor(bcolor);
	myvx(a);
	myvx(c);
	for(j = 0; j < sst->nh; j++){
	  a[0] = c[0] = (j+1) * sst->dotsiz[0] -fh;
	  b[0] = d[0] = (j+1) * sst->dotsiz[0] -fh;
	  if(*p & WHITEMODE)
	    mycolor(wcolor);
      else if(*p & GREYMODE)
          mycolor(pcolor);
	  else
	    mycolor(bcolor);
	  myvx(a);
	  myvx(c);
	  /*
	    myvx(c);
	    myvx(d);
	  */
	  p++;
	}
	glEnd();
      }
            
            
    }
    glPopMatrix();
  }
    
  int SaveRds(Stimulus *st, FILE *fd)
  {
    Locator *pos = &st->pos;
    vcoord offset[2],xp[5000],yp[5000],disps[5000];
    int *p,d,*end,i;
    vcoord  w,h,*x,*y,fw,fh,*pdisp;
    Substim *sst = st->left;
    short colors[5000];
    int ndots[2],sign = 1;
    double pixmul;
    static int nsaved = 0;
        
        
        
    /*
     * divide pixm by 2 because this disparity is applied
     * equal and opposite in each image
     */
    if(optionflag & ANTIALIAS_BIT)
      pixmul = deg2pix(1) * PIXM/2;
    else
      pixmul = deg2pix(1)/2;
        
    if(sin(st->pos.angle) < 0)
      sign = 1;
    else
      sign = -1;
        
    if(fd == NULL){
      fprintf(stderr,"Can't create rds\n");
      return(0);
    }
    nsaved++;
    if(testflags[SAVE_IMAGES] == 5)
      fprintf(fd,"BinocDisps RDS %s px %.4f\n",VERSION_NUMBER,deg2pix(1));
    else if(testflags[SAVE_IMAGES] != 6)
      fprintf(fd,"BinocFrame RDS %s\n",VERSION_NUMBER);
        
        
    offset[0] = pos->xy[0] + st->disp;
    offset[1] = pos->xy[1] + st->vdisp;
    p = sst->iim;
    x = sst->xpos;
    y = sst->ypos;
    pdisp = sst->imb;
    end = (sst->iim+sst->ndots);
    i = 0;
        
    /*
     * First write out left eye dot locations
     */
    for(;p < end; p++,x++,y++,pdisp++)
      {
	if(*p & BLACKMODE)
	  colors[i] = 0;
	else if(*p & WHITEMODE)
	  colors[i] = 1;
	if(*p & LEFTMODE){
	  xp[i] = *x+offset[0];
	  yp[i] = *y+offset[1];
	  disps[i] = sign * *pdisp/pixmul;
	  i++;
	}
	else{
	  xp[i] = 10000;
	  yp[i] = *y+offset[1];
	  disps[i] = sign * *pdisp/pixmul;
	  i++;
	}
      }
    ndots[0] = i;
        
    if(testflags[SAVE_IMAGES] == 6){
      fprintf(fd,"%d", st->left->seed);
      for(i = 0; i < ndots[0]; i++){
	if(xp[i] > 9999)
	  fprintf(fd," NaN");
	else
	  fprintf(fd," %.1f", xp[i]);
      }
      fprintf(fd,"\n");
      fprintf(fd,"%d", expt.allstimid);
      for(i = 0; i < ndots[0]; i++)
	fprintf(fd," %.1f", yp[i]);
      fprintf(fd,"\n");
      fprintf(fd,"%d",expt.framesdone);
      for(i = 0; i < ndots[0]; i++)
	fprintf(fd," %.1f", disps[i]);
      fprintf(fd,"\n");
      fprintf(fd,"NaN");
      for(i = 0; i < ndots[0]; i++)
	fprintf(fd," %d", colors[i]);
      fprintf(fd,"\n");
      return(ndots[0]);
    }
        
    fprintf(fd,"Id %d frame %d dots %d %d se%d %.1f,%.1f P %.1f %.1f\n",
	    expt.allstimid,expt.framesdone,ndots[0],ndots[1],st->left->seed,
	    xp[0],yp[0],pos->xy[0],pos->xy[1]);
        
    fwrite(xp,sizeof(vcoord),ndots[0], fd);
    fwrite(yp,sizeof(vcoord),ndots[0], fd);
    fwrite(colors,sizeof(short),ndots[0], fd);
    if(testflags[SAVE_IMAGES] == SAVE_RDS_DISPS){
      fwrite(disps,sizeof(vcoord),ndots[0], fd);
      return(ndots[0]);
    }
        
    /*
     * Then right eye dot locaitons
     */
    offset[0] = pos->xy[0] - st->disp;
    offset[1] = pos->xy[1] - st->vdisp;
    sst = st->right;
    p = sst->iim;
    x = sst->xpos;
    y = sst->ypos;
    end = (sst->iim+sst->ndots);
    i = 0;
    for(;p < end; p++,x++,y++)
      {
	if(*p & BLACKMODE)
	  colors[i] = 0;
	else if(*p & WHITEMODE)
	  colors[i] = 1;
	if(*p & RIGHTMODE){
	  xp[i] = *x+offset[0];
	  yp[i] = *y+offset[1];
	  i++;
	}
	else{
	  xp[i] = 10000;
	  yp[i] = 10000;
	  i++;
	}
      }
    ndots[1] = i;
        
    fwrite(xp,sizeof(vcoord),ndots[1], fd);
    fwrite(yp,sizeof(vcoord),ndots[1], fd);
    fwrite(colors,sizeof(short),ndots[1], fd);
    return(ndots[0]);
        
  }
    
    
    
  