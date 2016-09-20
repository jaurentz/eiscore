#include "eiscor.h"
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! d_symtrid_factor3 (chasing half up half down)
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! This routine performs a Cayley transformation of the symmetric
! tridiagonal matrix to a unitary matrix (a descending and a 
! ascending sequence of core transformations). The unitary matrix
! is transformed to upper Hessenberg form by core chasing.
!
! The Cayley (Moebius) transform -(z-i)/(z+i) maps the real line to
! the unit circle, in particular the interval [-1,1] is mapped to
! [-pi/2, pi/2]. 
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! INPUT VARIABLES:
!
!  VEC             LOGICAL
!                    .TRUE.: compute schurvectors
!                    .FALSE.: no schurvectors
!
!  ID              LOGICAL
!                    .TRUE.: initialize to Z to identity
!                    .FALSE.: assume Z is already initialized
!
!  SCA             LOGICAL
!                    .TRUE.: scale the matrix to 
!                            have eigenvalues in [-1,1]
!                    .FALSE.: do not scale the matrix
!                  !! CAUTION: Not scaling the matrix can 
!                              result in inaccurate eigenvalues !! 
! 
!  N               INTEGER
!                    dimension of matrix
!
!  D               REAL(8) array of dimension (N)  
!                    diagonal entries of T
!                    on exit: if SCA=.TRUE., D and E have been scaled
!
!  E               REAL(8) array of dimension (N-1)
!                    subdiagonal entries of T
!                    on exit: if SCA=.TRUE., D and E have been scaled
!
!  M               INTEGER
!                    leading dimension of Z
!
! OUTPUT VARIABLES:
!
!  Q               REAL(8) array of dimension (3*(N-1))
!                    array of generators for Givens rotations
!
!  QD              REAL(8) array of dimension (2*N)
!                    array of generators for complex diagonal matrix
!
!  SCALE           REAL(8) 
!                    scaling factor for back transform
!                    
!  Z               COMPLEX(8) array of dimension (M,N)
!                    similarity transformation of the reduction to 
!                    unitary Hessenberg form
!                    if VEC = .FALSE. unused
!                    if VEC = .TRUE. and ID = .TRUE. initializes Z to I 
!                    if VEC = .TRUE. and ID = .FALSE. assumes Z initialized
!
!  INFO            INTEGER
!                    INFO = 1 implies scaling failed
!                    INFO = 0 implies successful computation
!                    INFO = -4 implies N is invalid
!                    INFO = -5 implies D is invalid
!                    INFO = -6 implies E is invalid
!                    INFO = -10 implies M is invalid
!                    INFO = -11 implies Z is invalid
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subroutine d_symtrid_factor3(VEC,ID,SCA,N,D,E,Q,QD,SCALE,M,Z,INFO)

  implicit none
  
  ! input variables
  logical, intent(in) :: VEC, ID, SCA
  integer, intent(in) :: N, M
  real(8), intent(inout) :: D(N), E(N-1), Q(3*N-3), QD(2*N), SCALE
  complex(8), intent(inout) :: Z(M,N)
  integer, intent(inout) :: INFO

  ! compute variables
  integer :: ii, jj, ind1, ind2, N2
  logical :: flg
  real(8) :: cr, ci, s, nrm, bulge(3), hb(3), a, b, LD(2*N)     
  complex(8) :: eu, d1, t1(2,2)

  ! initialize INFO
  INFO = 0

  ! check N
  if (N < 1) then
    INFO = -4
    ! print error message in debug mode
    if (DEBUG) then
      call u_infocode_check(__FILE__,__LINE__,"N must be at least 1",INFO,INFO)
    end if
    return
  end if


  ! check D
  call d_1Darray_check(N,D,flg)
  if (.NOT.flg) then
    INFO = -5
    ! print error message in debug mode
    if (DEBUG) then
      call u_infocode_check(__FILE__,__LINE__,"D is invalid",INFO,INFO)
    end if
    return
  end if

  ! check E
  call d_1Darray_check(N-1,E,flg)
  if (.NOT.flg) then
    INFO = -6
    ! print error message in debug mode
    if (DEBUG) then
      call u_infocode_check(__FILE__,__LINE__,"E is invalid",INFO,INFO)
    end if
    return
  end if


  ! check M
  if (VEC.AND.(M < 1)) then
    INFO = -9
    ! print error message in debug mode
    if (DEBUG) then
      call u_infocode_check(__FILE__,__LINE__,"M must be at least 1",INFO,INFO)
    end if
    return
  end if
  
  ! check Z
  if (VEC.AND..NOT.ID) then
    call d_2Darray_check(M,N,Z,flg)
    if (.NOT.flg) then
      INFO = -10
      ! print error message in debug mode
      if (DEBUG) then
        call u_infocode_check(__FILE__,__LINE__,"Z is invalid",INFO,INFO)
      end if
      return
    end if
  end if   

  ! initialize Z
  if (VEC.AND.ID) then
     Z = cmplx(0d0,0d0,kind=8)
     do ii=1,min(M,N)
        Z(ii,ii) = cmplx(1d0,0d0,kind=8)
     end do
  end if

  ! scaling
  if (SCA) then
     ! .TRUE. : use Newton correction
     call d_symtrid_specint(.TRUE.,N,D,E,a,b,INFO)

     if (INFO.NE.0) then 
        ! print error in debug mode
        if (DEBUG) then
           call u_infocode_check(__FILE__,__LINE__,"d_symtrid_specint failed",INFO,INFO)
        end if
        INFO = 1

     end if
     
     SCALE = max(abs(a),abs(b))
     
     do ii=1,N
        D(ii) = D(ii)/SCALE
     end do
     do ii=1,N-1
        E(ii) = E(ii)/SCALE
     end do

  end if

  ! Cayley transform -(T-iI)(T+iI)              
  ! implicitly form B = T - i I  and T + i I = conjg(B)
  eu = E(1)
  d1 = cmplx(D(1),-1d0,kind=8)

  ! QR decomposition QR = (T-iI)
  do ii=1,N-1
     ! compute new rotation
     call z_rot3_vec3gen(dble(d1),aimag(d1),E(ii),cr,ci,s,nrm)
     
     Q(3*ii-2) = cr
     Q(3*ii-1) = ci
     Q(3*ii)   = s

     ! update banded matrix (ignoring the second superdiagonal and the upper part of the matrix)
     d1 = -s*eu + cmplx(cr,ci,kind=8)*cmplx(D(ii+1),-1d0,kind=8)
     if (ii<N-1) then
        eu = cmplx(cr*E(ii+1),ci*E(ii+1),kind=8)
     end if
  end do

  ! form diagonal R conjg(R)^-1 (which is a diagonal matrix) 
  do ii=1,N-1
     QD(2*ii-1) = -1d0
     QD(2*ii)   = 0d0
  end do
  call d_rot2_vec2gen(dble(d1),aimag(d1),cr,s,nrm)
  call d_rot2_vec2gen(-cr*cr+s*s,-2*cr*s,QD(2*N-1),QD(2*N),nrm)             

  ! chasing half down
  N2 = max(1,N/2-1)
  
  ! fuse Q^T into Q
  do jj=N-1,N2,-1
     bulge(1) = Q(3*jj-2)
     bulge(2) = Q(3*jj-1)
     bulge(3) = -Q(3*jj)  ! the bulge is Q^T

     ! main chasing loop
     do ii=jj,(N-2)
       
        ! set indices
        ind1 = 2*(ii-1) + 1
        ind2 = ind1+3
        
        ! through diag 
        call z_rot3_swapdiag(.FALSE.,QD(ind1:ind2),bulge)
        
        ! set indices
        ind1 = 3*(ii-1) + 1
        ind2 = ind1+2
        
        ! through Q
        call z_rot3_turnover(Q(ind1:ind2),Q((ind1+3):(ind2+3)),bulge)

        ! update eigenvectors
        if (VEC) then
           t1(1,1) = cmplx(bulge(1),bulge(2),kind=8)
           t1(2,1) = cmplx(bulge(3),0d0,kind=8)
           t1(1,2) = -t1(2,1)
           t1(2,2) = conjg(t1(1,1))
           Z(:,(ii+1):(ii+2)) = matmul(Z(:,(ii+1):(ii+2)),t1)
        end if

     end do
          
     ! set indices
     ind1 = 2*(N-2) + 1  
     ind2 = ind1+3
     
     ! through diag
     call z_rot3_swapdiag(.FALSE.,QD(ind1:ind2),bulge)
     
     ! fusion at bottom
     call z_unifact_mergebulge(.FALSE.,Q((3*N-5):(3*N-3)),QD((2*N-3):(2*N)),bulge)

  end do


  ! chasing half up
  
  ! initialize LD
  do ii=1,N
     LD(2*ii-1)= 1d0
     LD(2*ii) = 0d0
  end do
  
  ! fuse Q^T into Q
  do jj=1,N2-1
     !print*, "MITTE 4a d_spr1_factor",jj
     bulge(1) = Q(3*jj-2)
     bulge(2) = Q(3*jj-1)
     bulge(3) = -Q(3*jj)  ! the bulge is Q^T
     
     ! update eigenvectors
     if (VEC) then
        t1(1,1) = cmplx(bulge(1),-bulge(2),kind=8)
        t1(2,1) = cmplx(-bulge(3),0d0,kind=8)
        t1(1,2) = -t1(2,1)
        t1(2,2) = conjg(t1(1,1))
        Z(:,(jj):(jj+1)) = matmul(Z(:,(jj):(jj+1)),t1)
     end if
     
     ! set indices
     ind1 = 2*jj - 1
     ind2 = ind1 + 3
     
     ! through diag 
     call z_rot3_swapdiag(.TRUE.,LD(ind1:ind2),bulge)
     
     ! main chasing loop
     do ii=jj,2,-1
        
        !print*, "MITTE 4b d_spr1_factor",jj,ii
        ! set indices
        ind1 = 3*(ii-2) + 1
        ind2 = ind1+2
        
        ! through Q
        call z_rot3_turnover(bulge,Q(ind1:ind2),Q((ind1+3):(ind2+3)))
        hb = bulge
        bulge = Q(ind1:ind2)
        Q(ind1:ind2) = Q((ind1+3):(ind2+3))
        Q((ind1+3):(ind2+3)) = hb
        
        ! set indices
        ind1 = 2*(ii-2) + 1
        ind2 = ind1+3
       
        ! through diag 
        call z_rot3_swapdiag(.TRUE.,QD(ind1:ind2),bulge)
        !ind1 = 2*(ii-2) + 1
        !ind2 = 3*(ii-2) + 1
        !call z_upr1fact_rot3throughtri(.TRUE.,QD(ind1:ind1+3),QC(ind2:ind2+5),QB(ind2:ind2+5),bulge)
        
        ! update eigenvectors
        if (VEC) then
           t1(1,1) = cmplx(bulge(1),-bulge(2),kind=8)
           t1(2,1) = cmplx(-bulge(3),0d0,kind=8)
           t1(1,2) = -t1(2,1)
           t1(2,2) = conjg(t1(1,1))
           Z(:,(ii-1):(ii)) = matmul(Z(:,(ii-1):(ii)),t1)
        end if

        ! set indices
        ind1 = 2*(ii-2) + 1
        ind2 = ind1+3

        ! through diag 
        call z_rot3_swapdiag(.TRUE.,LD(ind1:ind2),bulge)
        
     end do
     
     ! fusion at bottom
     call z_unifact_mergebulge(.TRUE.,Q(1:3),QD(1:4),bulge)
     
     ! update LD(1:2)
     t1(1,1) = cmplx(LD(1),LD(2),kind=8)*cmplx(bulge(1),bulge(2),kind=8)
     call d_rot2_vec2gen(dble(t1(1,1)),aimag(t1(1,1)),LD(1),LD(2),nrm)

     ! update LD(3:4)
     t1(1,1) = cmplx(LD(3),LD(4),kind=8)*cmplx(bulge(1),-bulge(2),kind=8)
     call d_rot2_vec2gen(dble(t1(1,1)),aimag(t1(1,1)),LD(3),LD(4),nrm)

  end do

  ! merge LD in QD
  do ii=1,N-1
     ind1 = 2*ii-1
     ind2 = 3*ii-2
     call z_rot3_swapdiag(.FALSE.,LD(ind1:(ind1+3)),Q(ind2:(ind2+2)))
  end do
  do ii=1,N
     t1(1,1) = cmplx(LD(2*ii-1),LD(2*ii),kind=8)
     ! update U
     !U(ii) = conjg(t1(1,1))*U(ii)
     ! update eigenvectors
     !if (VEC) then
     !   Z(:,ii) = Z(:,ii)*t1(1,1)
     !end if
     
     t1(1,1) = cmplx(QD(2*ii-1),QD(2*ii),kind=8)*t1(1,1)
     call d_rot2_vec2gen(dble(t1(1,1)),aimag(t1(1,1)),QD(2*ii-1),QD(2*ii),nrm)
     
  end do
  
end subroutine d_symtrid_factor3
