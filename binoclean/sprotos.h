#ifndef STIMPROTOS
#define STIMPROTOS 1
OneStim *NewGrating(Stimulus *st, Substim *sst, Substim *copy);
OneStim *NewGrating2(Stimulus *st, Substim *sst, Substim *copy);
OneStim *NewGratingN(Stimulus *st, Substim *sst, Substim *copy);
void free_grating(Substim *st);
void init_grating(Stimulus *st, Substim *sst);
float CalcLum(float *p, float f, float y, float phase, float lumscale, float background);
float SetLum(float *p, float f, float y, float phase, float lumscale, float background);
void calc_grating(Stimulus *st, Substim *sst, float disp);
int SetGratingFrequencies(Stimulus *st);
double SetFreqOnOff433(Substim *sst, int nc);
double SetFreqOnOff(Substim *sst, int nc);
void paint_lines(Locator *pos, short *p, int ci);
void paint_grating(Substim *sst, int mode, int shift);
int SaveNSines(Stimulus *st, FILE *fd);
Substim *NewRds(Stimulus *st, Substim *sst, Substim  *copy);
Substim *NewChecker(Stimulus *st, Substim *sst, Substim  *copy);
void free_rds(Substim *st);
int CalcNdots(Substim *sst);
int init_rds(Stimulus *st,  Substim *sst, float density);
void PrintRDSDispCounts(FILE *ofd);
int precalc_rds_disps(Stimulus *st);
int calc_rds(Stimulus *st, Substim *sst);
void calc_rds_check(Stimulus *st, Substim *sst);
void testcalc_rds(Stimulus *st, Substim *sst, int mode);
void paint_rds(Stimulus *st, int mode);
void paint_rds_check(Stimulus *st, Substim *sst);
int SaveRds(Stimulus *st, FILE *fd);
Substim *NewRls(Stimulus *st, Substim *sst, Substim  *copy);
void free_rls(Substim *st);
int init_rls(Stimulus *st,  Substim *sst, float density);
void calc_rls(Stimulus *st, Substim *sst);
void calc_rls_polys(Stimulus *st, Substim *sst);
void paint_rls(Stimulus *st, int mode);
void paint_rls_polygons(Stimulus *st, int mode);
void paint_rls_lines(Stimulus *st, int mode);
int SaveRls(Stimulus *st, FILE *fd);
OneStim *NewBar(Stimulus *st,Substim *sst);
void free_bar(Substim *st);
void init_bar(Stimulus *st, Substim *sst);
void calc_bar(Stimulus *st);
void extent_bar(Stimulus *st, Rectangle *pr);
void paint_bar(Stimulus *st, Substim *sst, int mode);
OneStim *NewCylinder(Stimulus *st, Substim *sst, Substim  *copy);
ball_s *get_mem(int ndots);
void free_cylinder(Substim *st);
int paint_balls(Stimulus *st, int mode, OneStim *cyl,float *vcolor, float *bcolor,float *rotatefactor, float *hdotsize, int aa);
void paint_cylinder(Stimulus *st, int mode, double subtracting);
void plc_paint_cylinder(Stimulus *st);
void paint_track(Stimulus *st);
float calc_newoffset(float maxdisparity, float xpos);
float calc_offset(float minaxis, float x, float viewdist, float halfiod, int left_right);
void calc_cyl_motion(ball_s *balls, float vel, int ndots, int flag, int lifeframes, float deathchance, int width);
void calc_subpix_disp(ball_s *balls, int numdots, int flag, float disparity, Locator *pos, float widthfactor, float heightfactor);
OneStim *NewGabor(Stimulus *st, Substim *sst, Substim *copy);
void free_gabor_ptr(OneStim *ptr);
void free_gabor(Substim *st);
void init_gabor(Stimulus *st,  Substim *sst);
void calc_gabor(Stimulus *st, Substim *sst,  float disp);
void paint_gabor_pair(Stimulus *st);
void paint_gabor_lines(Substim *ssl, Substim  *gbr);
void colorvertex(float *x, float *z, float *p, float *q);
void paint_gabor(Stimulus *st, Substim *sst, int mode, int shift);
void optimize_gabor(Stimulus *st, Substim *sst);
OneStim *NewProbe(Stimulus *st,Substim *sst);
void free_probe(Substim *st);
void init_probe(Stimulus *st, Substim *sst);
void calc_probe(Stimulus *st);
void extent_probe(Stimulus *st, Rectangle *pr);
void paint_alt_probe(Stimulus *st, Substim *sst, int mode);
void paint_probe(Stimulus *st, Substim *sst, int mode);
OneStim *NewSquare(Stimulus *st,Substim *sst);
void free_square(Substim *st);
void init_square(Stimulus *st, Substim *sst);
void calc_square(Stimulus *st);
void extent_square(Stimulus *st, Rectangle *pr);
void paint_square(Stimulus *st, Substim *sst, int mode);
void init_test(Stimulus *st);
void calc_test(Stimulus *st);
void test_proc(Stimulus *st);
void paint_test(Stimulus *st);
void box(int ox, int oy, int ww, int wh);
void flatbox(int ox, int oy, int ww, int wh);
int OpenSerial(char *port);
int new_setup(int tty);
void restore_setup(int tty);
int closeserial(int tty);
char ReadSerial(int tty);
char *CheckSerialInput(int length);
void SerialString(char *s, int tty);
int FindCode(char *s);
int NewSeed(Stimulus *st);
int PrintInfo(FILE *fd);
int SetTargets();
void RunWaterAlarm();
void SetExpVals();
//int *AdjustEyePos(int len);
int CheckEyeDrift();
void write_windowpos(FILE *ofd);
void write_expvals(FILE *ofd, int flag);
int ResetCustomVals(int imode);
char *StairPerfString();
int mygreg_setstair(int result, AFCstructure *afc, double *expvals);
int SetMonkeyStaircase(int jonresult, AFCstructure *afc);
int SetAltStair(int up, int revise);
void write_sliders(FILE *ofd);
void write_menus(FILE *ofd);
void text_set_expvals();
unsigned int ufftime(struct timeval *thetime);
void PrintCodes(int mode);
void PrintPenLog(int scroll);
int InitRndArray(long seed, int len);
void ExptInit(Expt *ex, Stimulus *stim, Monitor *mon);
void SetPlotSizes(struct plotdata *plot);
void SetPenPanel();
void SetAllPanel(Expt *ex);
void setcomitem(char *text);
int ReadHelpDir(char *dir);
void SelectExp(int menuid, int code, int select);
struct plotdata *ReadPlot(char *s);
void SetExpPanel(Expt *ex);
int GetTotal(struct plotdata *plot, int cluster, int type);
void PrintPlot(FILE *ofd, struct plotdata *plot, int cluster, int type);
int SavePlot(struct plotdata *plot);
void PlotClear(struct plotdata *plot);
void psychclear(struct plotdata *plot, int allflag);
void PlotAlloc(Expt *exp);
int i2expi(int flag, int *nstim, int ival, int type);
double i2expval(int ival, int extras, int type, int skipx);
int PlotSet(Expt *exp, struct plotdata *plot);
int OpenPsychLog(char *name);
int OpenLogfile(char *name);
void InterpretChannelLine(char *line, int chan);
int CheckPenetration();
int SetExptString(Expt *exp, Stimulus *st, int flag, char *s);
int RecalcRepeats(Expt *exp);
int SetProperty(Expt *exp, Stimulus *st, int code, float val);
void ElectrodeDepth(int depth);
int SetExptProperty(Expt *exp, Stimulus *st, int flag, float val);
float GetProperty(Expt *exp, Stimulus *st, int code);
float ExptProperty(Expt *exp, int flag);
void setextras();
void CheckExpts();
GLubyte *GetStimImage(int x, int y, int w, int h, char eye);
int SaveImage(Stimulus *st, int type);
int ReadCommand(char *s);
char *ShowTextVal(int i, char *s);
void DoCommand(char *s);
void AddElectrodeString(char *s);
void AddUserString(char *s);
double pos2phase(Stimulus *st);
void CheckPlots(Expt *exp);
void PrintCounts(struct plotdata *plot, int type, int cluster);
float MaxTrialRate(struct plotdata *plot);
void MinMaxCounts(struct plotdata *plot, int type, int cluster);
void plotsymbol(vcoord x, vcoord y, vcoord w, int type);
int PlotLine(struct plotdata *plot, int cluster, int plotnum, int nstims);
int PlotSymbols(struct plotdata *plot, int cluster, int plotnum, int symbol, int nstims);
int PlotSequence(struct plotdata *plot, int cluster);
int PlotRow(struct plotdata *plot, int cluster, int plotnum, int nstims);
int PlotSpinSdf(int e2, int sign, struct plotdata *plot,int id);
void PlotCounts(struct plotdata *plot, int plotnum, int symbol, float color, int cluster);
void plotpsychdata(struct plotdata *plot);
void record_setup(int index, int store);
void ResetExpt();
void checkstimbuffers(int nstim, int nreps);
void setorderbits(int stimi);
int SetFirstStairVal();
int setexp3stim();
void setstimulusorder(int warnings);
int ASetStimulus(float val, int code, int * event, Stimulus * st);
int SetStimulus(Stimulus * st, float val, int code, int * event); 
int permute(int *in, int n);
int CountReps(int start);
void setstimuli(int flag);
void LoadBackgrounds();
int MakeString(int code, char *cbuf, Expt *ex, Stimulus *st, int flag);
char *SerialSend(int code);
void InitExpt();
Thisstim *getexpval(int stimi);
void ShuffleStimulus(int state);
void SetSacVal(float stimval, int index);
float ResetFixWin();
int SetDotDistribution(void);
int SetDotPlanes(Stimulus *st, double tf, double depth_mod);
char *ShowStimVals(Thisstim *stp);
int SetFrameStim(int i, long lrnd, double inc, Thisstim *stp, int *nstim);
int PrepareExptStim(int show, int caller);
void ResetExpStim(int offset);
int ExpStimOver(int retval, int lastchar);
int paint_strobehalf(int stimmode, int order);
int ExptTrialOver(int type);
int CheckBW(int signal, char *msg);
void framepause(int nf);
int ReplayExpt(char *name);
int ReadExptFile(char *name, int new, int show, int reset);
void SetPlotLabels(struct plotdata *plot);
int FindStimId(Expt *ex, AFCstructure *afc);
void inc_psychdata(int response_direction, Expt *ex, int jstimno);
void UnReadSpikes(Expt *ex);
int ReadSpikes(char *s, Expt *ex);
int ShowFlag(char *s, int flag);
int CheckOption(int i);
int ChangeFlag(char *s);
void SetPopup(char *s, int up);
int str2code(char *s);
float readval(char *s, 	Stimulus *TheStim);
int ReadMonitorSetup(char *name);
int LabelAndPath(char *s, char *sublabel, char *path, char *name);
int InterpretLine(char *line, Expt *ex, int frompc);
int ButtonResponse(int button, int revise, vcoord *locn);
char *DescribeStim(Stimulus *st);
int PrintPsychData(char *filename);
int isdir(char *path);
int ReadPGM(char *name, PGM *pgm);
float dogamma(float cindex);
void setmask(int type);
float pix2deg(float val);
float pix2degy(float val);
float deg2pix(float val);
float deg2pixy(float val);
Stimulus *NewStimulus(Stimulus *st);
void draw_cross(vcoord *pos, vcoord fixw);
void draw_pos(vcoord *pos, int fixw, float color);
void draw_fix_square(vcoord fixw);
void draw_conjpos(vcoord fixw, float color);
void draw_fix_cross(float fixw);
void draw_fix(vcoord px, vcoord py, vcoord fixw, float color);
void setgamma(double val);
void SetColor(float cindex, int correct);
void WipeBackRect(Stimulus *st, int dispflag, float color);
unsigned long *CheckBackrect(int w, int h, int flag);
void test_mem();
int clear_screen(Stimulus *st, int flag);
void FreeStimulus(Substim *st);
int StimulusType(Stimulus *st, int i);
void wipestim(Stimulus *st, int color);
void clearstim(Stimulus *st, float color, int drawfix);
void init_stimulus(Stimulus *st);
void calc_stimulus(Stimulus *st);
void clear_stimulus(Stimulus *st);
void paint_half(Stimulus *st, int mode, int noback);
void paint_stereo_stimulus(Stimulus *st);
void paint_stimulus(Stimulus *st);
void optimize_stimulus(Stimulus *st);
void mycirc(vcoord x, vcoord y, vcoord r);
void mycircle(vcoord x, vcoord y, vcoord r, int npts);
void aarect(vcoord llx, vcoord lly, vcoord urx, vcoord ury);
int Project(vcoord *x, int eye);
int grid(vcoord w, vcoord  h, int eye);
OneStim *GetOneStimPtr(Substim *sst);
float bw2cv(float bw);
void OpenStaircaseLog();
int greg_setstair(int result, AFCstructure *afc);
void reset_afc_counters();
void nullify(char *s, int length);
int find_direction(float expval);
int monkey_direction(int response, AFCstructure afc_s);
int loopstate_counters(int direction, int response);
int set_loop_state();
AFC_tots afccounters(int direction, int response);
void performance_string(float expval, int response, int state,  char **s1, char **s2, float sacval);
float set_stair_level(float lastval, int response, int state, float stairfactor, float maxval, float minval, stair_hist_s *shist);
stair_hist_s setup_stairstruct(float *startvalue, float stairfactor, float maxvalue, float minvalue);
void stair_counters(stair_hist_s *shist, int response);
void printstair(int staircounter,  int startbin,  int bincounter_min,  int bincounter_max, hist_structure *pstairbins);
void clearlogitem(int code);
void addcodetobuf(char *buf, int code);
void SaveUnitLog();
char *EyeCoilString(void);
void SetWPanel();
char *getfilename(char *path);
void SetBWPanel();
int SetBWChannel(int chan, char *s);
void SetAPanel();
stair_hist_s newstairstruct();
int PrintToggles(FILE *ofd);
char *binocTimeString();
void ShowTime();
int getframecount();
float getframetime();
int CheckStrings();
void initial_setup();
void SetPriority(int priority);
float GetFrameRate(void);
void SendAll();
void MakeConnection();
void SetPanelColor(float color);
void glstatusline(char *s, int line);
void statusline(char *s);
void ResetProjectionMatrix();
int TrialOver();
void StopGo(int go);
void SetStopButton(int onoff);
void Box(int a, int b, int c, int d, float color);
void VisLine(int a, int b, int c, int d, float color);
float getangle(vcoord *wp, vcoord *sp);
void win2stim(vcoord *wp, vcoord *sp, float angle, vcoord *result);
vcoord StimLine(vcoord *pos, Expstim *es, float color);
int events_pending();
void TurnBackStim(Stimulus *st);
void StartRunning();
char DummySerial();
void one_event_loop();
void event_loop();
void SetDelay(Locator *pos);
void CheckRect(Stimulus *st);
int StartOverlay();
int EndOverlay();
int ShowBox(Expstim *ps, float color);
void RotateStimulus(int x, int y);
void LocateStimulus(Stimulus *st, vcoord x, vcoord y);
void ShowDataPos(struct plotdata *plot, int x, int y);
void ShowPos(int x, int y);
void monocwipe();
void clear_display(int flag);
void redraw_overlay(struct plotdata  *plot);
int step_stimulus();
void clear_overlay();
void nsine_background();
void search_background();
void start_timeout(int mode);
void end_timeout();
void SendMovements();
void WriteSignal();
int change_frame();
int SetRandomPhase( Stimulus *st,     Locator *pos);
void increment_stimulus(Stimulus *st, Locator *pos);
void PaintBackIm(PGM im);
void wipescreen(float color);
void paint_frame(int type, int showfix);
int CheckFix();
int RunBetweenTrials(Stimulus *st, Locator *pos);
int StartTrial();
int StartStimulus(Stimulus *st);
void ShowInfo();
void testcolor();
int next_frame(Stimulus *st);
void expback();
void exprun();
void frameback();
void framefront();
void expfront();
void makewindow(char *s);
void init_windows();
void set_test_loop();
void lwrect(vcoord llx, vcoord lly, vcoord urx, vcoord ury);
void rotrect(vcoord *line, vcoord x, vcoord y);
void aarotrect(vcoord *line, vcoord x, vcoord y);
void inrect(vcoord llx, vcoord lly, vcoord urx, vcoord ury);
void run_rds_test_loop();
void run_gabor_test_loop();
void run_anticorrelated_test_loop();
void run_general_test_loop();
void run_swap_test_loop();
void fsleep(float f);
float StimulusProperty(Stimulus *st, int code);
void NewFixPos(float x, float y);
void SetStimPanel(Stimulus *st);
void test_button();
void SetStimPopupPanel();
void panel_popup();
void update_option_display();
void setoption();
int BackupStimFile();
void SaveExptFile(char *filename,int flag);
void select_stimulus(int type);
void CheckMode(int cmode);
float timediff(struct timeval *a, struct timeval *b);
void addtime(struct timeval *a, struct timeval *b, float sec);
void GLblock(int n);
void WurtzTrial();
float StimDuration();
float StimTime(struct timeval *event);
int ShowTrialCount(float down, float sum);
int ShowLastCodes();
void ShowConjugReadState(char *line);
double  RunTime(void );
int GotChar(char c);
void SerialSignal(char flag);
void CloseLog(void);
void paint_target(float color, int flag);
void ShowPerformanceString(int force);
void afc_statusline(char *s, int line);
void PaintGammaCheck(int iw, int ih);
void chessboard(float w, float h);
void makeRasterFont(void);
void printString(char *s, int size);
void WriteFrameData();
void expt_over(int flag);
void Stim2PsychFile();
void HideCursor(void);
void ReopenSerial(void);
OneStim *NewCorrug(Stimulus *st, Substim *sst, Substim  *copy);
void free_corrug(Substim *st);
int init_corrug(Stimulus *st,  Substim *sst, float density);
void calc_corrug(Stimulus *st, Substim *sst);
void calc_plane(Stimulus *st, Substim *sst);
void paint_corrug(Stimulus *st, int mode);
OneStim *NewSqcorrug(Stimulus *st, Substim *sst, Substim  *copy);
void free_sqcorrug(Substim *st);
int init_sqcorrug(Stimulus *st,  Substim *sst, float density);
void calc_sqcorrug(Stimulus *st, Substim *sst);
int square_wave(float sin_value);
void paint_sqcorrug(Stimulus *st, int mode);
OneStim *Newtwobar(Stimulus *st,Substim *sst);
void paint_twobar(Stimulus *st, Substim *sst, int mode);
float get_polarangle(float x, float y);
char *getRenderer(void);
void mySwapBuffers();
void ctest_button();
static void settimeout();
int OpenStepSerial(char *port);
int steptty_setup(int tty);
void stepsetup(void);
void reopen_button();
void steptest_button();
float StepProperty(int code);
void SendStepProp(int prop);
void SendAllStepProps(int channel);
void SetMotorId(int id);
void selectMotor(int motorNum);
void setCurrentPosition(int pos);
void setNewPosition(int pos, int diff);
void NewPosition(int pos);
void ControlsetNewPosition(int pos, int diff);
int shutdown_stepper(void);
int plottrack(struct plotdata *plot);
int ReadPenSteps(char *penfile);
long rnd_i ();
unsigned long rnd_u ();
long rnd_ri (long rng);
double rnd_01d ();
double rnd_ned (double lam);
void init_radial(Stimulus *st, Substim *sst);
OneStim *NewRadial(Stimulus *st, Substim *sst, Substim *copy);
void free_radial(Substim *st);
void paint_radial(Substim *sst, int mode, int shift);
float SetRadial(int ix, int iy, int w, int h, Substim *sst, int type);
void precalc_radial(Stimulus *st, Substim *sst, float disp);
void calc_radial(Stimulus *st, Substim *sst, float disp);
Substim *NewImage(Stimulus *st, Substim *sst);
int init_image(Stimulus *st,  Substim *sst);
int ReadPGMstim(char *name, Substim *sst);
int CopyPGMstim(Substim *src, Substim *tgt);
void calc_image(Stimulus *st, Substim *sst);
int paint_image(Stimulus *st, Substim *sst);
void runexpt(int w, Stimulus *st, int *cbs);
void setexp(int w, int id, int val);
void setsecondexp(int w, int id, int val);
int HandleMouse(WindowEvent e);
int MyLine(int a, int b, int c, int d, float color);
void MakePlotLabel(struct plotdata *plot, char *s, int i, int flip);

#endif
