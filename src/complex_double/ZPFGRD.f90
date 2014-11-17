!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! ZPFGRD (Zomplex unitary Plus rank 1 hessenberg Factored Givens Rotation Deflation)
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! This routine checks for deflations in an upper hessenberg matrix 
! that is the sum of a unitary matrix and a rank one matrix. This sum 
! is stored as a product of three sequences of Givens' rotations and a 
! complex unimodular diagonal matrix. When a deflation occurs the 
! corresponding rotation in the first sequence of rotations is set to 
! the identity matrix.
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! INPUT VARIABLES:
!
!  N               INTEGER
!                    dimension of matrix
!
!  STR             INTEGER
!                    index of the top most givens rotation where 
!                    deflation should be checked
!
!  STP             INTEGER
!                    index of the bottom most givens rotation where 
!                    deflation should be checked
!
!  Q               REAL(8) array of dimension (3*N)
!                    array of generators for first sequence of Givens' 
!                    rotations
!
!  D               REAL(8) array of dimension (2*(N+2))
!                    array of generators for complex diagonal matrix
!                    on output contains the eigenvalues
!
!  C               REAL(8) array of dimension (3*N)
!                    array of generators for second sequence of Givens' 
!                    rotations
!
!  B               REAL(8) array of dimension (3*N)
!                    array of generators for third sequence of Givens' 
!                    rotations
!
!  ITCNT           INTEGER
!                    number of iterations since last deflation
!
! OUTPUT VARIABLES:
!
!  ZERO            INTEGER
!                     index of the last known deflation
!                     on output contains index of newest deflation
!
!  ITS             INTEGER array of dimension (N-1)
!                    Contains the number of iterations per deflation
!
!  INFO            INTEGER
!                    INFO equal to 0 implies successful computation.
!                    INFO negative implies that an input variable has
!                    an improper value, i.e. INFO=-2 => STR is invalid
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subroutine ZPFGRD(N,STR,STP,ZERO,Q,D,C,B,ITCNT,ITS,INFO)

  implicit none
  
  ! input variables
  integer, intent(in) :: N
  integer, intent(inout) :: STR, STP, ZERO, ITCNT, INFO
  real(8), intent(inout) :: Q(3*N), D(2*(N+1)), C(3*N), B(3*N)
  integer, intent(inout) :: ITS(N-1)

  ! compute variables
  integer :: ii, ind1, ll, jj, k
  real(8) :: tol, nrm
  real(8) :: d1r, d1i, c1r, c1i, s
  
  ! initialize info
  INFO = 0
  
  ! check N
  if (N < 2) then
    INFO = -1
    write(*,*) "Error in "//__FILE__//" line:",__LINE__
    write(*,*) "N must be at least 2"
    write(*,*) ""
    return
  end if
  
  ! check STR
  if ((STR < 1).OR.(STR > N-1)) then
    INFO = -2
    write(*,*) "Error in "//__FILE__//" line:",__LINE__
    write(*,*) "Must hold: 1 <= STR <= N-1"
    write(*,*) ""
    return
  end if
  
  ! check STP
  if ((STP < STR).OR.(STP > N-1)) then
    INFO = -3
    write(*,*) "Error in "//__FILE__//" line:",__LINE__
    write(*,*) "Must hold: STR <= STP <= N-1"
    write(*,*) ""
    return
  end if
  
  ! check ITCNT
  if (ITCNT < 0) then
    INFO = -7
    write(*,*) "Error in "//__FILE__//" line:",__LINE__
    write(*,*) "ITCNT must be >= 0"
    write(*,*) ""
    return
  end if
  
  ! set tolerance
  tol = epsilon(1d0)
  
  ! check for deflation
  do ii=1,(STP-STR+1)
  
    ! one less than the index of the rotaion being checked
    ind1 = 3*(STP-ii)
     
    ! deflate if subdiagonal is small enough
    nrm = abs(Q(ind1+3))
    if(nrm < tol)then
        
      ! set sub-diagonal to 0
      Q(ind1+3) = 0d0
        
      ! update first diagonal
      c1r = Q(ind1+1)
      c1i = Q(ind1+2)
      Q(ind1+1) = 1d0
      Q(ind1+2) = 0d0
        
<<<<<<< HEAD
      ind1 = 2*(STP-ii)  
=======
      ind1 = 2*(STP-ii)	
>>>>>>> added files for complex unitary plus rank one from svn repo
      d1r = D(ind1+1)
      d1i = D(ind1+2)
        
      nrm = c1r*d1r - c1i*d1i
      d1i = c1r*d1i + c1i*d1r
      d1r = nrm
      nrm = sqrt(d1r*d1r + d1i*d1i)
      if (nrm.NE.0) then
        d1r = d1r/nrm
        d1i = d1i/nrm
      else
        d1r = 0d0
        d1i = 0d0
      end if
        
      D(ind1+1) = d1r
      D(ind1+2) = d1i
        
      ! 1x1 deflation
      if(ii == 1)then
        
        ! update second diagonal
<<<<<<< HEAD
        ind1 = 2*(STP-ii)  
=======
        ind1 = 2*(STP-ii)	
>>>>>>> added files for complex unitary plus rank one from svn repo
        d1r = D(ind1+3)
        d1i = D(ind1+4)
           
        nrm = c1r*d1r + c1i*d1i
        d1i = c1r*d1i - c1i*d1r
        d1r = nrm
        nrm = sqrt(d1r*d1r + d1i*d1i)
        d1r = d1r/nrm
        d1i = d1i/nrm
           
        D(ind1+3) = d1r
<<<<<<< HEAD
        D(ind1+4) = d1i      
=======
        D(ind1+4) = d1i			
>>>>>>> added files for complex unitary plus rank one from svn repo
           
        ! 2x2 or bigger
        else

          ! update Q
          do ll=(STP+1-ii),(STP-1)
            ind1 = 3*(ll)
            d1r = Q(ind1+1)
            d1i = Q(ind1+2)
            s = Q(ind1+3)
              
            nrm = c1r*d1r + c1i*d1i
            d1i = c1r*d1i - c1i*d1r
            d1r = nrm
            nrm = sqrt(d1r*d1r + d1i*d1i + s*s)
            d1r = d1r/nrm
            d1i = d1i/nrm
            s = s/nrm
              
            Q(ind1+1) = d1r
            Q(ind1+2) = d1i
            Q(ind1+3) = s
          end do
           
          ! update second diagonal
<<<<<<< HEAD
          ind1 = 2*(STP)  
=======
          ind1 = 2*(STP)	
>>>>>>> added files for complex unitary plus rank one from svn repo
          d1r = D(ind1+1)
          d1i = D(ind1+2)
           
          nrm = c1r*d1r + c1i*d1i
          d1i = c1r*d1i - c1i*d1r
          d1r = nrm
          nrm = sqrt(d1r*d1r + d1i*d1i)
          d1r = d1r/nrm
          d1i = d1i/nrm
           
          D(ind1+1) = d1r
          D(ind1+2) = d1i
        end if
<<<<<<< HEAD
  
=======
	
>>>>>>> added files for complex unitary plus rank one from svn repo
        ! update indices
        ZERO = STP+1-ii
        STR = ZERO + 1
        
        ! store it_count
        ITS(ZERO) = ITCNT
        ITCNT = 0
        
        exit
     end if
  end do
  
end subroutine ZPFGRD
