/* Calculus related functions
    Usage:
    - Create a math function following the signature "float f(float& in x)"
    - Call either the differential operator function "d_dx" or integral operator function "i_dx",
    passing in the function handle of your function, and the "x" value you want to calculate
    Examples:
    d_dx( @f, 5 );
    i_dx( @f, 5 );
    Integral operator function also has an additonal parameter to specify the lower integration limit, which is 0 be default

    Known issues:
    -Integral results with -ve limits will be incorrect because of the way intelgrals are computed. Use +ve values only.
*/
funcdef float FofX(float& in);

const float h = 1000.0f;
// e^x
float exp(float& in x = 1)
{
    return pow( x, 2.718281828459045 );
}
// Any base logarithm
float log_b(float& in b, float& in x)
{
    return log( x ) / log( b );
}
// d/dx f(x)
float d_dx(FofX@ f, float& in x) 
{
    if( f is null )
        return 0;

    const float dx = 1 / h;

    return ( f( x + dx ) - f( x - dx ) ) / ( 2 * dx );
}
// ∫f(x) dx
float i_dx(FofX@ f, float& in x, float& in a = 0) 
{
    if( f is null || x == a )
        return 0;

    const float dx = ( x - a ) / h;
    float S = 0;

    for( float fl = a + dx; fl < x; fl += dx )
        S += 2 * f( fl );

    return ( dx / 2 ) * ( f( a ) + S + f( x ) );
}
