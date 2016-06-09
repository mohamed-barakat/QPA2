DeclareRepresentation( "IsQPAMatrixRep",
                       IsComponentObjectRep and IsAttributeStoringRep,
                       [] );
DeclareRepresentation( "IsRowMatrixRep",
                       IsQPAMatrixRep,
                       [ "rows" ] );
DeclareRepresentation( "IsColMatrixRep",
                       IsQPAMatrixRep,
                       [ "cols" ] );

BindGlobal( "FamilyOfQPAMatrices",
            NewFamily( "matrices" ) );

BindGlobal( "MAKE_QPA_MATRIX",
function( R, M, type )
  local dim, dim_, matrix;
  dim_ := DimensionsMat( M );
  if type = IsRowMatrixRep then
    matrix := rec( rows := M );
    dim := dim_;
  elif type = IsColMatrixRep then
    matrix := rec( cols := M );
    dim := Reversed( dim_ );
  else
    Error( "wrong type" );
  fi;
  if IsIdentityMat( M ) then
    return IdentityMatrix( R, Length( M ) );
  elif M = NullMat( dim_[ 1 ], dim_[ 2 ], R ) then
    return MakeZeroMatrix( R, dim[ 1 ], dim[ 2 ] );
  fi;
  ObjectifyWithAttributes
    ( matrix,
      NewType( FamilyOfQPAMatrices, IsQPAMatrix and type ),
      BaseDomain, R,
      DimensionsMat, dim,
      IsIdentityMatrix, false,
      IsZeroMatrix, false );
  return matrix;
end );

InstallMethod( MatrixByRows, "for ring and matrix",
               [ IsRing, IsMatrix ],
function( R, M )
  return MAKE_QPA_MATRIX( R, M, IsRowMatrixRep );
end );

InstallMethod( MatrixByCols, "for ring and matrix",
               [ IsRing, IsMatrix ],
function( R, M )
  return MAKE_QPA_MATRIX( R, M, IsColMatrixRep );
end );

InstallMethod( IdentityMatrix, "for ring and integer",
               [ IsRing, IsInt ],
function( R, n )
  local matrix;
  if n < 0 then
    Error( "negative matrix dimension" );
  fi;
  matrix := rec();
  ObjectifyWithAttributes
    ( matrix,
      NewType( FamilyOfQPAMatrices, IsQPAMatrix and IsQPAMatrixRep ),
      BaseDomain, R,
      DimensionsMat, [ n, n ],
      IsIdentityMatrix, true,
      IsZeroMatrix, n = 0 );
  return matrix;
end );

InstallMethod( MakeZeroMatrix, "for ring and integers",
               [ IsRing, IsInt, IsInt ],
function( R, m, n )
  local matrix;
  if m < 0 or n < 0 then
    Error( "negative matrix dimension" );
  fi;
  matrix := rec();
  ObjectifyWithAttributes
    ( matrix,
      NewType( FamilyOfQPAMatrices, IsQPAMatrix and IsQPAMatrixRep ),
      BaseDomain, R,
      DimensionsMat, [ m, n ],
      IsIdentityMatrix, m = 0 and n = 0,
      IsZeroMatrix, true );
  return matrix;
end );

InstallMethod( RowsOfMatrix, "for QPA matrix",
               [ IsQPAMatrix ],
function( M )
  local dim;
  dim := DimensionsMat( M );
  return List( [ 1 .. dim[ 1 ] ],
               i -> List( [ 1 .. dim[ 2 ] ],
                          j -> MatElm( M, i, j ) ) );
end );

InstallMethod( ColsOfMatrix, "for QPA matrix",
               [ IsQPAMatrix ],
function( M )
  local dim;
  dim := DimensionsMat( M );
  return List( [ 1 .. dim[ 2 ] ],
               j -> List( [ 1 .. dim[ 1 ] ],
                          i -> MatElm( M, i, j ) ) );
end );

InstallMethod( RowsOfMatrix, "for row matrix",
               [ IsQPAMatrix and IsRowMatrixRep ],
function( M )
  return M!.rows;
end );

InstallMethod( ColsOfMatrix, "for row matrix",
               [ IsQPAMatrix and IsRowMatrixRep ],
function( M )
  return TransposedMat( M!.rows );
end );

InstallMethod( RowsOfMatrix, "for col matrix",
               [ IsQPAMatrix and IsColMatrixRep ],
function( M )
  return TransposedMat( M!.cols );
end );

InstallMethod( ColsOfMatrix, "for col matrix",
               [ IsQPAMatrix and IsColMatrixRep ],
function( M )
  return M!.cols;
end );

InstallMethod( TransposedMat, "for row matrix",
               [ IsQPAMatrix and IsRowMatrixRep ],
function( M )
  return MAKE_QPA_MATRIX( BaseDomain( M ), M!.rows, IsColMatrixRep );
end );

InstallMethod( TransposedMat, "for col matrix",
               [ IsQPAMatrix and IsColMatrixRep ],
function( M )
  return MAKE_QPA_MATRIX( BaseDomain( M ), M!.cols, IsRowMatrixRep );
end );

InstallMethod( TransposedMat, "for identity matrix",
               [ IsIdentityMatrix ],
               IdFunc );

InstallMethod( TransposedMat, "for zero matrix",
               [ IsZeroMatrix ],
function( M )
  local dim;
  dim := DimensionsMat( M );
  return MakeZeroMatrix( BaseDomain( M ), dim[ 2 ], dim[ 1 ] );
end );

InstallMethod( MatElm, "for QPA matrix and positive integers",
               [ IsQPAMatrix, IsPosInt, IsPosInt ],
               1000,
function( M, i, j )
  local dim;
  dim := DimensionsMat( M );
  if i > dim[ 1 ] or j > dim[ 2 ] then
    Error( "position (", i, ",", j, ") is outside ", dim[ 1 ], "x", dim[ 2 ], " matrix" );
  fi;
  TryNextMethod();
end );

InstallMethod( MatElm, "for row matrix and positive integers",
               [ IsQPAMatrix and IsRowMatrixRep, IsPosInt, IsPosInt ],
function( M, i, j )
  return M!.rows[ i ][ j ];
end );

InstallMethod( MatElm, "for col matrix and positive integers",
               [ IsQPAMatrix and IsColMatrixRep, IsPosInt, IsPosInt ],
function( M, i, j )
  return M!.cols[ j ][ i ];
end );

InstallMethod( MatElm, "for identity matrix and positive integers",
               [ IsIdentityMatrix, IsPosInt, IsPosInt ],
function( M, i, j )
  if i = j then
    return One( BaseDomain( M ) );
  else
    return Zero( BaseDomain( M ) );
  fi;
end );

InstallMethod( MatElm, "for zero matrix and positive integers",
               [ IsZeroMatrix, IsPosInt, IsPosInt ],
function( M, i, j )
  return Zero( BaseDomain( M ) );
end );

InstallMethod( ViewObj, "for QPA matrix",
               [ IsQPAMatrix ],
function( M )
  Print( String( M ) );
end );

InstallMethod( String, "for QPA matrix",
               [ IsQPAMatrix ],
function( M )
  local dim, type;
  dim := DimensionsMat( M );
  type := "";
  if dim[ 1 ] = 0 or dim[ 2 ] = 0 then
    type := " empty";
  elif IsZeroMatrix( M ) then
    type := " zero";
  elif IsIdentityMatrix( M ) then
    type := " identity";
  fi;
  return Concatenation
         ( "<", String( dim[ 1 ] ), "x", String( dim[ 2 ] ),
           type, " matrix over ", String( BaseDomain( M ) ), ">" );
end );

InstallMethod( \*, "for QPA matrices",
               [ IsQPAMatrix, IsQPAMatrix ],
function( M1, M2 )
  local R, dim1, dim2;
  R := BaseDomain( M1 );
  dim1 := DimensionsMat( M1 );
  dim2 := DimensionsMat( M2 );
  if R <> BaseDomain( M2 ) then
    Error( "matrices over different rings" );
  elif dim1[ 2 ] <> dim2[ 1 ] then
    Error( "dimensions of matrices do not match" );
  elif IsZeroMatrix( M1 ) or IsZeroMatrix( M2 ) then
    return MakeZeroMatrix( R, dim1[ 1 ], dim2[ 2 ] );
  elif IsIdentityMatrix( M1 ) then
    return M2;
  elif IsIdentityMatrix( M2 ) then
    return M1;
  elif IsColMatrixRep( M1 ) then
    return MAKE_QPA_MATRIX( R, ColsOfMatrix( M2 ) * ColsOfMatrix( M1 ),
                            IsColMatrixRep );
  else
    return MAKE_QPA_MATRIX( R, RowsOfMatrix( M1 ) * RowsOfMatrix( M2 ),
                            IsRowMatrixRep );
  fi;
end );

InstallMethod( \+, "for QPA matrices",
               [ IsQPAMatrix, IsQPAMatrix ],
function( M1, M2 )
  local R, dim;
  R := BaseDomain( M1 );
  dim := DimensionsMat( M1 );
  if R <> BaseDomain( M2 ) then
    Error( "matrices over different rings" );
  elif dim <> DimensionsMat( M2 ) then
    Error( "dimensions of matrices do not match" );
  elif IsZeroMatrix( M1 ) then
    return M2;
  elif IsZeroMatrix( M2 ) then
    return M1;
  elif IsColMatrixRep( M1 ) or IsColMatrixRep( M2 ) then
    return MAKE_QPA_MATRIX( R, ColsOfMatrix( M1 ) + ColsOfMatrix( M2 ),
                            IsColMatrixRep );
  else
    return MAKE_QPA_MATRIX( R, RowsOfMatrix( M1 ) + RowsOfMatrix( M2 ),
                            IsRowMatrixRep );
  fi;
end );

InstallMethod( AdditiveInverseMutable, "for QPA matrices",
               [ IsQPAMatrix ],
function( M )
  local R, dim;
  R := BaseDomain( M );
  dim := DimensionsMat( M );
  if IsZeroMatrix( M ) then
    return M;
  elif IsColMatrixRep( M ) then
    return MAKE_QPA_MATRIX( R, - ColsOfMatrix( M ), IsColMatrixRep );
  else
    return MAKE_QPA_MATRIX( R, - RowsOfMatrix( M ), IsRowMatrixRep );
  fi;
end );

InstallMethod( \*, "for QPA row vector and QPA matrix",
               [ IsQPARowVector, IsQPAMatrix ],
function( v, M )
  local R, dim;
  R := BaseDomain( M );
  dim := DimensionsMat( M );
  if R <> LeftActingDomain( SpaceContainingVector( v ) ) then
    Error( "vector and matrix not over same field" );
  elif Length( v ) <> dim[ 1 ] then
    Error( "can not multiply vector of length ", Length( v ), " with ",
           dim[ 1 ], "x", dim[ 2 ], " matrix" );
  fi;
  if dim[ 2 ] = 0 then
    return EmptyVector( R );
  elif dim[ 1 ] = 0 then
    return Zero( RowVectorSpace( R, dim[ 2 ] ) );
  else
    return RowVector( R, AsList( v ) * RowsOfMatrix( M ) );
  fi;
end );

InstallMethod( \*, "for QPA matrix and QPA column matrix",
               [ IsQPAMatrix, IsQPAColVector ],
function( M, v )
  Error( "not implemented" ); #TODO fix
end );

InstallMethod( \=, "for QPA matrices",
               [ IsQPAMatrix, IsQPAMatrix ],
function( M1, M2 )
  local dim, i, j;
  dim := DimensionsMat( M1 );
  if dim <> DimensionsMat( M2 ) then
    return false;
  fi;
  for i in [ 1 .. dim[ 1 ] ] do
    for j in [ 1 .. dim[ 2 ] ] do
      if MatElm( M1, i, j ) <> MatElm( M2, i, j ) then
        return false;
      fi;
    od;
  od;
  return true;
end );

InstallMethod( IsZero, "for QPA matrix", [ IsQPAMatrix ],
function( M )
  local dim, i, j;
  dim := DimensionsMat( M );
  for i in [ 1 .. dim[ 1 ] ] do
    for j in [ 1 .. dim[ 2 ] ] do
      if not IsZero( MatElm( M, i, j ) ) then
        return false;
      fi;
    od;
  od;
  return true;
end );

InstallMethod( SolutionMat, "for QPA matrix and a row vector",
	       [ IsQPAMatrix, IsQPARowVector ], NICE_FLAGS + 1000, 
function( M, v )
  local   dim,  V;

  dim := DimensionsMat( M );
  if dim[ 2 ] <> Length( v ) then
    Error("a row vector of length ",Length( v )," cannot be in the image of a ",
          dim[ 1 ]," x ",dim[ 2 ],"-matrix,\n"); 
  fi;
  if dim[ 1 ] = 0 then
    if IsZero( v ) then
      return EmptyVector( BaseDomain( M ) );
    else
      return fail;
    fi;
  fi;
  V :=  RowVectorSpace( BaseDomain( M ), dim[ 1 ] );
  if dim[ 2 ] = 0 then
    return Zero( V );
  else
    return Vector( V, SolutionMat( RowsOfMatrix( M ), AsList( v ) ) );
  fi;
end 
);