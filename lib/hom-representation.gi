InstallMethod( Hom, "for positive integer and quiver representations",
               [ IsPosInt, IsQuiverRepresentation, IsQuiverRepresentation ],
function( s, R1, R2 )
  local hom_functor;
  hom_functor := HomFunctor( s, CapCategory( R1 ), CapCategory( R2 ) );
  return ApplyFunctor( hom_functor, R1, R2 );
end );

InstallMethod( Hom, "for positive integer, quiver representation and quiver representation homomorphism",
               [ IsPosInt, IsQuiverRepresentation, IsQuiverRepresentationHomomorphism ],
function( s, R, m )
  local hom_functor;
  hom_functor := HomFunctor( s, CapCategory( R ), CapCategory( m ) );
  return ApplyFunctor( hom_functor, IdentityMorphism( R ), m );
end );

InstallMethod( Hom, "for positive integer, quiver representation homomorphism and quiver representation",
               [ IsPosInt, IsQuiverRepresentationHomomorphism, IsQuiverRepresentation ],
function( s, m, R )
  local hom_functor;
  hom_functor := HomFunctor( s, CapCategory( m ), CapCategory( R ) );
  return ApplyFunctor( hom_functor, m, IdentityMorphism( R ) );
end );

InstallMethod( Hom, "for positive integer and quiver representation homomorphisms",
               [ IsPosInt, IsQuiverRepresentation, IsQuiverRepresentation ],
function( s, m1, m2 )
  local hom_functor;
  hom_functor := HomFunctor( s, CapCategory( m1 ), CapCategory( m2 ) );
  return ApplyFunctor( hom_functor, m1, m2 );
end );

InstallMethod( HomFunctor,
               [ IsQuiverRepresentationCategory ],
function( cat )
  local hom, morphism_fun;
  hom := CapFunctor( "Hom",
                     [ [ cat, true ], [ cat, false ] ],
                     VectorSpaceCategory( cat ) );
  AddObjectFunction( hom, Hom );
  morphism_fun := function( source, f1, f2, range )
    return Hom( f1, f2 );
  end;
  AddMorphismFunction( hom, morphism_fun );
  return hom;
end );

InstallMethod( HomFunctor,
               [ IsPosInt, IsQuiverRepresentationCategory, IsQuiverRepresentationCategory ],
function( s, cat1, cat2 )
  local t, T1, T2, algs1, A1, B1, pre_functor_1, algs2, A2, B2, 
        pre_functor_2, A, hom_A, map_hom, compute_hom_functor, range, 
        hom_functor, hom;
  if not s in [ 1, 2 ] then
    Error( "tensor factor number must be either 1 or 2, not ", s );
  fi;
  t := 3 - s;
  T1 := AlgebraOfCategory( cat1 );
  T2 := AlgebraOfCategory( cat2 );
  if IsTensorProductOfAlgebras( T1 ) then
    algs1 := TensorProductFactors( T1 );
    A1 := algs1[ s ];
    B1 := algs1[ t ];
    pre_functor_1 := AsLayeredRepresentationFunctor( s, cat1 );
  else
    A1 := T1;
    B1 := fail;
    pre_functor_1 := IdentityFunctor( cat1 );
  fi;
  if IsTensorProductOfAlgebras( T2 ) then
    algs2 := TensorProductFactors( T2 );
    A2 := algs2[ s ];
    B2 := algs2[ t ];
    pre_functor_2 := AsLayeredRepresentationFunctor( s, cat2 );
  else
    A2 := T2;
    B2 := fail;
    pre_functor_2 := IdentityFunctor( cat2 );
  fi;
  if A1 <> A2 then
    Error( "incompatible categories" );
  fi;
  A := A1;
  if B1 = fail and B2 = fail then
    return HomFunctor( cat1 );
  else
    hom_A := HomFunctor( CategoryOfQuiverRepresentations( A ) ); # Hom_A(-,-)
    map_hom := MapRepresentation( hom_A, [ B1, B2 ] );
    compute_hom_functor := PreComposeFunctors( [ pre_functor_1, pre_functor_2 ], map_hom );
    range := AsCapCategory( Range( compute_hom_functor ) );
    hom_functor := CapFunctor( "Hom",
                               [ [ cat1, true ], [ cat2, false ] ],
                               range );
    AddObjectFunction( hom_functor, function( R1, R2 )
      local hom;
      hom := ApplyFunctor( compute_hom_functor, R1, R2 );
      SetFilterObj( hom, IsHomRepresentation );
      SetSource( hom, R1 );
      SetRange( hom, R2 );
      return hom;
    end );
    AddMorphismFunction( hom_functor, FunctorMorphismOperation( compute_hom_functor ) );
    return hom_functor;
  fi;
end );

InstallMethod( HomFunctor,
               [ IsPosInt, IsQuiverRepresentation, IsQuiverRepresentationCategory ],
function( s, R, cat )
  return FixFunctorArguments( HomFunctor( s, CapCategory( R ), cat ),
                              [ R, fail ] );
end );

InstallMethod( HomFunctor,
               [ IsPosInt, IsQuiverRepresentationCategory, IsQuiverRepresentation ],
function( s, cat, R )
  return FixFunctorArguments( HomFunctor( s, cat, CapCategory( R ) ),
                              [ fail, R ] );
end );

InstallMethod( HomFunctor,
               [ IsFieldCategoryObject, IsFieldCategory ],
function( obj, cat )
  if not IsIdenticalObj( CapCategory( obj ), cat ) then
    Error( "object from wrong category" );
  fi;
  return FixFunctorArguments( HomFunctor( cat ), [ obj, fail ] );
end );

InstallMethod( HomFunctor,
               [ IsFieldCategory, IsFieldCategoryObject ],
function( cat, obj )
  if not IsIdenticalObj( CapCategory( obj ), cat ) then
    Error( "object from wrong category" );
  fi;
  return FixFunctorArguments( HomFunctor( cat ), [ fail, obj ] );
end );


InstallMethod( PreComposeFunctors,
               [ IsCapFunctor, IsCapFunctor ],
function( F, G )
  local sig_F, sig_G, range_F, range_G, sig, i, n, name, result, 
        object_fun, morphism_fun;
  sig_F := InputSignature( F );
  sig_G := InputSignature( G );
  range_F := AsCapCategory( Range( F ) );
  range_G := AsCapCategory( Range( G ) );
  if Length( sig_G ) > 1 then
    Error( "functor to be composed must be unary" );
  fi;
  if not IsIdenticalObj( sig_G[ 1 ][ 1 ], range_F ) then
    Error( "non-composable functors" );
  fi;
  sig := ShallowCopy( sig_F );
  if sig_G[ 1 ][ 2 ] then # G is contravariant
    for i in [ 1 .. Length( sig ) ] do
      sig[ i ][ 2 ] := not sig[ i ][ 2 ];
    od;
  fi;
  n := Length( sig );

  name := Concatenation( "Composition of ", Name( F ), " and ", Name( G ) );

  result := CapFunctor( name, sig, range_G );

  object_fun := function( arg )
    local result_of_F;
    result_of_F := CallFuncList( ApplyFunctor, Concatenation( [ F ], arg ) );
    return ApplyFunctor( G, result_of_F );
  end;
  AddObjectFunction( result, object_fun );

  morphism_fun := function( arg )
    local result_of_F;
    result_of_F := CallFuncList( ApplyFunctor, Concatenation( [ F ], arg{ [ 2 .. n + 1 ] } ) );
    return ApplyFunctor( G, result_of_F );
  end;
  AddMorphismFunction( result, morphism_fun );

  return result;
end );


InstallMethod( PreComposeFunctors,
               [ IsDenseList, IsCapFunctor ],
function( Fs, G )
  local sig_G, sig_Fs, range_G, n_G, i, argument_indices, acc, sig, n, 
        j, name, result, object_fun, morphism_fun;
  sig_G := InputSignature( G );
  sig_Fs := List( Fs, InputSignature );
  range_G := AsCapCategory( Range( G ) );

  if Length( sig_G ) <> Length( Fs ) then
    Error( "length of list does not match arity of functor" );
  fi;
  n_G := Length( sig_G );
  for i in [ 1 .. n_G ] do
    if not IsIdenticalObj( AsCapCategory( Range( Fs[ i ] ) ),
                           sig_G[ i ][ 1 ] ) then
      Error( "non-composable functors" );
    fi;
  od;

  argument_indices := [];
  acc := 0;
  for i in [ 1 .. n_G ] do
    argument_indices[ i ] := [ acc + 1, acc + Length( sig_Fs[ i ] ) ];
    acc := acc + Length( sig_Fs[ i ] );
  od;
  
  sig := Concatenation( sig_Fs );
  n := Length( sig );
  for i in [ 1 .. n_G ] do
    sig[ i ] := ShallowCopy( sig[ i ] );
    if sig_G[ i ][ 2 ] then # G is contravariant in its i-th argument
      for j in [ argument_indices[ i ][ 1 ] .. argument_indices[ i ][ 2 ] ] do
        sig[ j ][ 2 ] := not sig[ j ][ 2 ];
      od;
    fi;
  od;

  name := Concatenation( "Composition of ",
                         JoinStringsWithSeparator( List( Fs, Name ), "," ),
                         " and ", Name( G ) );

  result := CapFunctor( name, sig, range_G );

  object_fun := function( arg )
    local result_of_Fs, i, args_i;
    result_of_Fs := [];
    for i in [ 1 .. n_G ] do
      args_i := arg{ [ argument_indices[ i ][ 1 ] .. argument_indices[ i ][ 2 ] ] };
      result_of_Fs[ i ] := CallFuncList( ApplyFunctor, Concatenation( [ Fs[ i ] ], args_i ) );
    od;
    return CallFuncList( ApplyFunctor, Concatenation( [ G ], result_of_Fs ) );
  end;
  AddObjectFunction( result, object_fun );
  
  morphism_fun := function( arg )
    local args, result_of_Fs, i, args_i;
    args := arg{ [ 2 .. n + 1 ] };
    result_of_Fs := [];
    for i in [ 1 .. n_G ] do
      args_i := args{ [ argument_indices[ i ][ 1 ] .. argument_indices[ i ][ 2 ] ] };
      result_of_Fs[ i ] := CallFuncList( ApplyFunctor, Concatenation( [ Fs[ i ] ], args_i ) );
    od;
    return CallFuncList( ApplyFunctor, Concatenation( [ G ], result_of_Fs ) );
  end;
  AddMorphismFunction( result, morphism_fun );

  return result;
end );

InstallMethod( FixFunctorArguments,
               [ IsCapFunctor, IsDenseList ],
function( F, args )
  local sig_F, n, sig, blank_positions, i, name, object_fun, 
        morphism_fun, fixed_F;
  sig_F := InputSignature( F );
  if Length( sig_F ) <> Length( args ) then
    Error( "length of argument list does not match arity of functor" );
  fi;
  n := Length( sig_F );
  sig := [];
  blank_positions := [];
  for i in [ 1 .. n ] do
    if args[ i ] = fail then
      Add( blank_positions, i );
      Add( sig, sig_F[ i ] );
    elif not IsIdenticalObj( CapCategory( args[ i ] ), sig_F[ i ][ 1 ] ) then
      Error( "fixed argument at position ", i, " is in wrong category" );
    fi;
  od;

  name := Concatenation( Name( F ), "(" );
  for i in [ 1 .. n ] do
    if args[ i ] = fail then
      name := Concatenation( name, "-" );
    elif HasName( args[ i ] ) then
      name := Concatenation( name, Name( args[ i ] ) );
    else
      name := Concatenation( name, String( args[ i ] ) );
    fi;
    if i < n then
      name := Concatenation( name, "," );
    fi;
  od;
  name := Concatenation( name, ")" );
  
  object_fun := function( arg )
    local args_F;
    args_F := ShallowCopy( args );
    args_F{ blank_positions } := arg;
    return CallFuncList( ApplyFunctor, Concatenation( [ F ], args_F ) );
  end;
  morphism_fun := function( arg )
    local args_F;
    args_F := ShallowCopy( args );
    args_F{ blank_positions } := arg{ [ 2 .. Length( arg ) - 1 ] };
    return CallFuncList( ApplyFunctor, Concatenation( [ F ], args_F ) );
  end;

  fixed_F := CapFunctor( name, sig, AsCapCategory( Range( F ) ) );
  AddObjectFunction( fixed_F, object_fun );
  AddMorphismFunction( fixed_F, morphism_fun );
  return fixed_F;
end );
