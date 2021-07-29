      implicit real *8 (a-h,o-z)
      real *8, allocatable :: source(:,:),targ(:,:),targc(:,:)
      real *8, allocatable :: dipvec(:,:,:)
      real *8, allocatable :: charge(:,:),dipstr(:,:)
      real *8, allocatable :: quadstr(:,:),quadvec(:,:,:)
      real *8, allocatable :: octstr(:,:),octvec(:,:,:)
      real *8, allocatable :: pot(:,:),grad(:,:,:),
     1     hess(:,:,:)
      real *8, allocatable :: potex(:,:),gradex(:,:,:),
     1     hessex(:,:,:), carray(:,:)
      real *8 :: center1(2), center2(2), center3(2)
      complex *16, allocatable :: mbhmpole(:,:), ympole(:,:)
      complex *16, allocatable :: mbhmpole1(:,:,:), ympole1(:,:,:)      
      complex *16, allocatable :: mbhloc(:,:), lloc(:,:)
      complex *16, allocatable :: mbhlocc(:,:), llocc(:,:)
      
      character(len=72) str1
      parameter (ntestmax = 200)
      integer ipass(ntestmax)
      
      complex *16 ima,zbeta
      data ima/(0.0d0,1.0d0)/

      call prini(6,13)

      done = 1
      pi = atan(done)*4

      nsrc = 40
      ntarg = 20
      nd = 3
      allocate(source(2,nsrc),charge(nd,nsrc),dipstr(nd,nsrc))
      allocate(targ(2,ntarg),targc(2,ntarg),dipvec(nd,2,nsrc))
      allocate(quadstr(nd,nsrc),quadvec(nd,3,nsrc))
      allocate(octstr(nd,nsrc),octvec(nd,4,nsrc))      
      allocate(pot(nd,ntarg),grad(nd,2,ntarg),
     1     hess(nd,3,ntarg))
      allocate(potex(nd,ntarg),gradex(nd,2,ntarg),
     1     hessex(nd,3,ntarg))


c
c     test explanation
c
c     ________________________
c    |       |       |  T    |
c    |  S    |       |_______|
c    |       |       |   | C |
c    |_______|_______|___|___|
c
c     Sources are randomly placed in the
c     box S = [0,1]\times [0,1]
c     Targets are randomly placed in the
c     boxes T = [2,3]\times[0,1] and
c     its child C = [2.5,3]\times[0,0.5]
c
c     Then the following tests are done
c
c     (a) form multipole expansion directly from sources in S
c     centered at center of S, evaluate at targets in T
c     and compare to true values
c     (b) form local expansion directly from sources in S
c     centered at center of T, evaluate at targets in T
c     and compare to true values
c     (c) form local expansion centered at center of C
c     by translating expansion from part (b), evaluate at
c     targets and compare to truth

      do i=1,nsrc
         source(1,i) = hkrand(0)
         source(2,i) = hkrand(0)
         do l = 1,nd
            charge(l,i) = hkrand(0)
            dipstr(l,i) = hkrand(0) 
            dipvec(l,1,i) = hkrand(0)
            dipvec(l,2,i) = hkrand(0)
            quadstr(l,i) = hkrand(0) 
            quadvec(l,1,i) = hkrand(0)
            quadvec(l,2,i) = hkrand(0)
            quadvec(l,3,i) = hkrand(0)
            octstr(l,i) = hkrand(0) 
            octvec(l,1,i) = hkrand(0)
            octvec(l,2,i) = hkrand(0)
            octvec(l,3,i) = hkrand(0)
            octvec(l,4,i) = hkrand(0)   
         enddo
      enddo

      center1(1) = 0.5d0
      center1(2) = 0.5d0

      do i=1,ntarg
         targ(1,i) = 2+hkrand(0)
         targ(2,i) = hkrand(0)
         targc(1,i) = 2.5d0 + 0.5d0*hkrand(0)
         targc(2,i) = 0.5d0*hkrand(0)
      enddo

      center2(1) = 2.5d0
      center2(2) = 0.5d0

      center3(1) = 2.75d0
      center3(2) = 0.25d0

c
c
      beta = 1d-5
      zbeta = ima*beta
      eps = 0.51d-12
      bsize1 = 1
      bsizec = 0.5d0
      rscale = min(abs(zbeta*bsize1/(2.0d0*pi)),1.0d0)
      rscalec = min(abs(zbeta*bsizec/(2.0d0*pi)),1.0d0)
      call l2dterms(eps,ntermsl,ier)

      nterms = ntermsl+5
      nterms1 = 3
      ldc = nterms+10
      allocate(mbhmpole(nd,0:nterms),ympole(nd,0:nterms),
     1     mbhmpole1(nd,0:nterms1,nsrc),ympole1(nd,0:nterms1,nsrc),
     2     mbhloc(nd,0:nterms),lloc(nd,0:nterms),
     2     mbhlocc(nd,0:nterms),llocc(nd,0:nterms),carray(0:ldc,0:ldc))

      call mbh2d_init_carray(carray,ldc)

      call prin2('rscale= *',rscale,1)
      call prinf('nterms = *',nterms,1)
      
      

      write(*,*) "=========================================="
      write(*,*) "Testing suite for mbhrouts/kernels2d"
      write(6,*)
      write(6,*)

      open(unit=33,file='print_testres.txt',access='append')


      do i=1,ntestmax
        ipass(i) = 0
      enddo

      thresh = 2.0d0**(-51)

      ntest = 0
c
c     test out = p for int-ker = c
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = c'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 0
      ifq = 0
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directcp_vec(nd,beta,source,nsrc,
     1        charge,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = d
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = d'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 1
      ifq = 0
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directdp_vec(nd,beta,source,nsrc,
     1        dipstr,dipvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = cd
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = cd'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 1
      ifq = 0
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directcdp_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = q
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = q'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 0
      ifq = 1
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directqp_vec(nd,beta,source,nsrc,
     1        quadstr,quadvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = cq
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = cq'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 0
      ifq = 1
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directcqp_vec(nd,beta,source,nsrc,
     1        charge,quadstr,quadvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = dq
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = dq'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 1
      ifq = 1
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directdqp_vec(nd,beta,source,nsrc,
     1        dipstr,dipvec,quadstr,quadvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = cdq
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = cdq'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 1
      ifq = 1
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directcdqp_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,quadstr,quadvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = o
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = o'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 0
      ifq = 0
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directop_vec(nd,beta,source,nsrc,
     1        octstr,octvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = co
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = co'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 0
      ifq = 0
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directcop_vec(nd,beta,source,nsrc,
     1        charge,octstr,octvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = do
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = do'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 1
      ifq = 0
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directdop_vec(nd,beta,source,nsrc,
     1        dipstr,dipvec,octstr,octvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = cdo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = cdo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 1
      ifq = 0
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directcdop_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,octstr,octvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = qo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = qo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 0
      ifq = 1
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directqop_vec(nd,beta,source,nsrc,
     1        quadstr,quadvec,octstr,octvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = cqo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = cqo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 0
      ifq = 1
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directcqop_vec(nd,beta,source,nsrc,
     1        charge,quadstr,quadvec,octstr,octvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = dqo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = dqo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 1
      ifq = 1
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directdqop_vec(nd,beta,source,nsrc,
     1        dipstr,dipvec,quadstr,quadvec,octstr,octvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = p for int-ker = cdqo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = p, ker = cdqo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 1
      ifq = 1
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalp_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot)

      do i = 1,ntarg
         call mbh2d_directcdqop_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,quadstr,quadvec,octstr,octvec,
     2        targ(1,i),potex(1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalp_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      write(*,*) errpot
      if(errpot .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = c
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = c'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 0
      ifq = 0
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directcg_vec(nd,beta,source,nsrc,
     1        charge,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = d
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = d'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 1
      ifq = 0
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directdg_vec(nd,beta,source,nsrc,
     1        dipstr,dipvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = cd
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = cd'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 1
      ifq = 0
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directcdg_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = q
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = q'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 0
      ifq = 1
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directqg_vec(nd,beta,source,nsrc,
     1        quadstr,quadvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = cq
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = cq'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 0
      ifq = 1
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directcqg_vec(nd,beta,source,nsrc,
     1        charge,quadstr,quadvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = dq
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = dq'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 1
      ifq = 1
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directdqg_vec(nd,beta,source,nsrc,
     1        dipstr,dipvec,quadstr,quadvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = cdq
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = cdq'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 1
      ifq = 1
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directcdqg_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,quadstr,quadvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = o
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = o'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 0
      ifq = 0
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directog_vec(nd,beta,source,nsrc,
     1        octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = co
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = co'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 0
      ifq = 0
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directcog_vec(nd,beta,source,nsrc,
     1        charge,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = do
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = do'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 1
      ifq = 0
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directdog_vec(nd,beta,source,nsrc,
     1        dipstr,dipvec,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = cdo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = cdo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 1
      ifq = 0
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directcdog_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = qo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = qo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 0
      ifq = 1
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directqog_vec(nd,beta,source,nsrc,
     1        quadstr,quadvec,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = cqo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = cqo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 0
      ifq = 1
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directcqog_vec(nd,beta,source,nsrc,
     1        charge,quadstr,quadvec,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = dqo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = dqo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 1
      ifq = 1
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directdqog_vec(nd,beta,source,nsrc,
     1        dipstr,dipvec,quadstr,quadvec,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = g for int-ker = cdqo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = g, ker = cdqo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 1
      ifq = 1
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalg_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad)

      do i = 1,ntarg
         call mbh2d_directcdqog_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,quadstr,quadvec,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),thresh)
      enddo
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalg_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad)

c
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      write(*,*) errpot, errgrad
      if(errpot .lt. eps .and. errgrad/10 .lt. eps) ipass(ntest) = 1

      
c
c     test out = h for int-ker = c
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = c'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 0
      ifq = 0
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directch_vec(nd,beta,source,nsrc,
     1        charge,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = d
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = d'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 1
      ifq = 0
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directdh_vec(nd,beta,source,nsrc,
     1        dipstr,dipvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = cd
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = cd'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 1
      ifq = 0
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directcdh_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = q
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = q'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 0
      ifq = 1
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directqh_vec(nd,beta,source,nsrc,
     1        quadstr,quadvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = cq
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = cq'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 0
      ifq = 1
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directcqh_vec(nd,beta,source,nsrc,
     1        charge,quadstr,quadvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = dq
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = dq'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 1
      ifq = 1
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directdqh_vec(nd,beta,source,nsrc,
     1        dipstr,dipvec,quadstr,quadvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = cdq
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = cdq'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 1
      ifq = 1
      ifo = 0

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directcdqh_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,quadstr,quadvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = o
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = o'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 0
      ifq = 0
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directoh_vec(nd,beta,source,nsrc,
     1        octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = co
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = co'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 0
      ifq = 0
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directcoh_vec(nd,beta,source,nsrc,
     1        charge,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = do
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = do'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 1
      ifq = 0
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directdoh_vec(nd,beta,source,nsrc,
     1        dipstr,dipvec,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = cdo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = cdo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 1
      ifq = 0
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directcdoh_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = qo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = qo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 0
      ifq = 1
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directqoh_vec(nd,beta,source,nsrc,
     1        quadstr,quadvec,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = cqo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = cqo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 0
      ifq = 1
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directcqoh_vec(nd,beta,source,nsrc,
     1        charge,quadstr,quadvec,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = dqo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = dqo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 0
      ifd = 1
      ifq = 1
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directdqoh_vec(nd,beta,source,nsrc,
     1        dipstr,dipvec,quadstr,quadvec,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c
c     test out = h for int-ker = cdqo
c     vs multipole
c

      write(*,*) '--------------------------------------------------'
      write(*,*) 'testing out = h, ker = cdqo'

      ntest = ntest+1

      write(*,*) 'multipoles test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms1+1)*nsrc,mbhmpole1)
      call testzero(2*nd*(nterms1+1)*nsrc,ympole1)
      call testzero(2*nd*(nterms+1),mbhmpole)
      call testzero(2*nd*(nterms+1),ympole)
      ifc = 1
      ifd = 1
      ifq = 1
      ifo = 1

      call mbh2dconvtomp_vec(nd,beta,nsrc,ifc,charge,
     1     ifd,dipstr,dipvec,ifq,quadstr,quadvec,ifo,octstr,
     2     octvec,nterms1,mbhmpole1,ympole1)

      call mbh2dformmpmp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center1,nterms,mbhmpole,ympole)

c      call prin2('mbhmpole *',mbhmpole,nd*2*(nterms+1))
c      call prin2('ympole *',ympole,nd*2*(nterms+1))      
      
      call mbh2dmpevalh_vec(nd,beta,rscale,center1,
     1     mbhmpole,ympole,nterms,targ,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directcdqoh_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,quadstr,quadvec,octstr,octvec,
     2        targ(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      ntest = ntest+1

      write(*,*) 'local exps test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(2*nd*(nterms+1),mbhloc)
      call testzero(2*nd*(nterms+1),lloc)

      call mbh2dformtamp_vec(nd,beta,rscale,source,nsrc,
     1     mbhmpole1,ympole1,nterms1,center2,nterms,mbhloc,lloc)

c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscale,center2,
     1     mbhloc,lloc,nterms,targ,ntarg,
     2     pot,grad,hess)

c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      
c     only need to test locloc for one case really...
      
      ntest = ntest+1

      write(*,*) 'locloc map test is test number: ', ntest
      
      call testzero(nd*ntarg,pot)
      call testzero(2*nd*ntarg,grad)
      call testzero(3*nd*ntarg,hess)            
      call testzero(nd*ntarg,potex)
      call testzero(2*nd*ntarg,gradex)
      call testzero(3*nd*ntarg,hessex)            
      call testzero(2*nd*(nterms+1),mbhlocc)
      call testzero(2*nd*(nterms+1),llocc)

      call mbh2dlocloc_vec(nd,beta,rscale,center2,mbhloc,lloc,
     1     nterms,rscalec,center3,mbhlocc,llocc,nterms,carray,ldc)


c      call prin2('mbhloc *',mbhloc,2*nd*(nterms+1))
c      call prin2('lloc *',lloc,2*nd*(nterms+1))      
      
      call mbh2dtaevalh_vec(nd,beta,rscalec,center3,
     1     mbhlocc,llocc,nterms,targc,ntarg,
     2     pot,grad,hess)

      do i = 1,ntarg
         call mbh2d_directcdqoh_vec(nd,beta,source,nsrc,
     1        charge,dipstr,dipvec,quadstr,quadvec,octstr,octvec,
     2        targc(1,i),potex(1,i),gradex(1,1,i),hessex(1,1,i),thresh)
      enddo

      
c      
      call testerr(nd*ntarg,potex,pot,errpot)
      call testerr(2*nd*ntarg,gradex,grad,errgrad)
      call testerr(3*nd*ntarg,hessex,hess,errhess)
      write(*,*) errpot, errgrad, errhess
      if(errpot .lt. eps .and. errgrad/10 .lt. eps
     1     .and. errhess/100 .lt. eps)
     1     ipass(ntest) = 1

      isum = 0
      do i=1,ntest
        isum = isum+ipass(i)
      enddo

      write(*,*) '--------------------------------------------------'
      
      call prinf('ipass *',ipass,ntest)

      write(*,'(a,i2,a,i2,a)') 'Successfully completed ',isum,
     1   ' out of ',ntest,' tests in mbhrouts/kernel2d testing suite'
      write(33,'(a,i2,a,i2,a)') 'Successfully completed ',isum,
     1   ' out of ',ntest,' tests in mbhrouts/kernel2d testing suite'
      close(33)
      


      stop
      end
c      
c
c

      subroutine testzero(n,v)
      implicit real *8 (a-h,o-z)
      real *8 :: v(*)
      
      do i = 1,n
         v(i)=0
      enddo

      return
      end

      subroutine testerr(n,vex,v,errv)
      implicit real *8 (a-h,o-z)
      real *8 :: v(*), vex(*)
      
      s = 0
      s1 = 0
      do i = 1,n
         s = s+(vex(i)-v(i))**2
         s1 = s1+(vex(i))**2
      enddo

      errv=sqrt(s/s1)
      return
      end
    
