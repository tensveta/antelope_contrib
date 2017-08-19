#include <stdlib.h>
#include <stdio.h>
#include <string>
#include <iostream>
#include <fstream>
#include <memory>
#include "seispp.h"
#include "ensemble.h"
#include "StreamObjectReader.h"
#include "StreamObjectWriter.h"
using namespace std;   
using namespace SEISPP;
void usage()
{
    cerr << "export_to_matlab [-v -text -o outfile --help] < in"
        <<endl
        << "Write data in a single TimeSeriesEnsemble object to a text matrix"<<endl
        << "that can be easily read into matlab (load procedure)"<<endl
        << "Use -o outfile to write the data to outfile.  By default the "<<endl
        << "matrix data are written to stdout"<<endl
        << "WARNING:  make sure the input has a relative time standard or span a single time window"<<endl
        << " -v - be more verbose"<<endl
        << " --help - prints this message"<<endl
        << " -text - switch to text input and output (default is binary)"<<endl;
    exit(-1);
}
dmatrix convert_to_matrix(TimeSeriesEnsemble& d)
{
  try{
    vector<TimeSeries>::iterator dptr;
    double dt,tmin,tmax;
    int i,j;
    for(i=0,dptr=d.member.begin();dptr!=d.member.end();++i,++dptr)
    {
      if(i==0)
      {
        tmin=dptr->time(0);
        tmax=dptr->endtime();
        dt=dptr->dt;
      }
      else
      {
        tmin=min(tmin,dptr->time(0));
        tmax=max(tmax,dptr->endtime());
        /* Bad form here using a fixed constant to define equivalent
        sample rates */
        if(fabs(dt-dptr->dt)>0.0001)
        {
          cerr << "export_to_matlab:  Mixmatched sample rates in input ensemble"<<endl
            << "This program requires fixed sample rate"<<endl
            << "Member "<<i<<" has dt="<<dptr->dt<<" but previous members had dt="
            << dt<<endl<<"No output will be generated"<<endl;
          exit(-1);
        }
      }
    }
    int n=d.member.size();
    int m= (int)((tmax-tmin)/dt);
    if(SEISPP_verbose)
    {
      cerr << "export_to_matlab:  time range of output="<<tmin<<" to "<<tmax<<endl;
      cerr << " computed number of samples="<<m<<endl
        << " from "<<n<<" seismograms in the input gather"<<endl;;
    }
    /* fixed wall as sanity check */
    const int Mmax(100000000);
    if(m>Mmax)
    {
      cerr << "export_to_matlab:  Computed number of samples,"<<m<<",  is very large."<<endl
          << "Aborting to avoid a likely malloc error."<<endl
          << "You are probably and ensmble with absolute times set as t0 instead of some relative time standard"<<endl;
      exit(-1);
    }
    dmatrix work(m,n);
    work.zero();
    for(j=0,dptr=d.member.begin();dptr!=d.member.end();++j,++dptr)
    {
      double t;
      for(t=tmin;t<tmax;t+=dt)
      {
        int kd,km;
        kd=dptr->sample_number(t);
        if( (kd>=0) && (kd<dptr->ns) )
        {
          if(kd<m)
            work(kd,j)=dptr->s[kd];
        }
      }
    }
    return work;
  }catch(...){throw;};
}
bool SEISPP::SEISPP_verbose(false);
int main(int argc, char **argv)
{
    int i;
    if(argc>1)
      if(string(argv[1])=="--help") usage();
    bool binary_data(true);
    bool write_to_stdout(true);
    string outfile;

    for(i=1;i<argc;++i)
    {
        string sarg(argv[i]);
        if(sarg=="--help")
        {
            usage();
        }
        else if(sarg=="-text")
        {
            binary_data=false;
        }
        else if(sarg=="-v")
          SEISPP_verbose=true;
        else if(sarg=="-o")
        {
          ++i;
          if(i>=argc) usage();
          outfile=string(argv[i]);
          write_to_stdout=false;
        }
        else
            usage();
    }
    try{
        shared_ptr<StreamObjectReader<TimeSeriesEnsemble>> inp;
        if(binary_data)
        {
          inp=shared_ptr<StreamObjectReader<TimeSeriesEnsemble>>
             (new StreamObjectReader<TimeSeriesEnsemble>('b'));
        }
        else
        {
          inp=shared_ptr<StreamObjectReader<TimeSeriesEnsemble>>
             (new StreamObjectReader<TimeSeriesEnsemble>);
        }
        TimeSeriesEnsemble d;
        d=inp->read();
        dmatrix dmat;
        dmat=convert_to_matrix(d);
        if(write_to_stdout)
          cout << dmat;
        else
        {
          ofstream ofs;
          ofs.open(outfile.c_str(),ios::out);
          if(ofs.fail())
          {
            cerr << "export_to_matlab:  open failed for output file="<<outfile<<endl
              << "Data not saved"<<endl;
            usage();
          }
          ofs << dmat;
          ofs.close();
        }
    }catch(SeisppError& serr)
    {
        serr.log_error();
    }
    catch(std::exception& stexc)
    {
        cerr << stexc.what()<<endl;
    }
}

