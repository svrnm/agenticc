program gcd_program
    implicit none
    integer :: a, b, result
    character(len=20) :: arg1, arg2
    
    ! Check if we have exactly 2 arguments
    if (command_argument_count() /= 2) then
        write(*,*) 'Usage: gcd <num1> <num2>'
        stop
    end if
    
    ! Read command-line arguments
    call get_command_argument(1, arg1)
    call get_command_argument(2, arg2)
    
    ! Convert strings to integers
    read(arg1, *) a
    read(arg2, *) b
    
    ! Compute GCD
    result = gcd(a, b)
    
    ! Print result
    write(*,*) result
    
contains
    ! Euclidean algorithm for GCD
    function gcd(x, y) result(res)
        integer, intent(in) :: x, y
        integer :: res
        integer :: temp_x, temp_y, temp
        
        temp_x = abs(x)
        temp_y = abs(y)
        
        do while (temp_y /= 0)
            temp = temp_y
            temp_y = mod(temp_x, temp_y)
            temp_x = temp
        end do
        
        res = temp_x
    end function gcd
    
end program gcd_program

