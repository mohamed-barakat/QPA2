#! @Chapter Modules

#! @Section Module homomorphisms

#! @Description
#!  Category for module homomorphisms.
DeclareCategory( "IsQuiverModuleHomomorphism",
                 IsMapping and IsSPGeneralMapping and IsVectorSpaceHomomorphism and
                 IsCapCategoryMorphism );

#! @Description
#!  Category for left module homomorphisms.
DeclareCategory( "IsLeftQuiverModuleHomomorphism",
                 IsQuiverModuleHomomorphism );

#! @Description
#!  Category for right module homomorphisms.
DeclareCategory( "IsRightQuiverModuleHomomorphism",
                 IsQuiverModuleHomomorphism );

#! @BeginGroup QuiverModuleHomomorphism
#! @Description
#!  Create a homomorphism from <A>M</A> to <A>N</A>.
#!  The list <A>matrices</A> contain matrices describing the map for each vertex.
#! @Returns <Ref Filt="IsQuiverModuleHomomorphism"/>
#! @Arguments M, N, matrices
DeclareOperation( "QuiverModuleHomomorphism",
                  [ IsQuiverModule, IsQuiverModule, IsList ] );
#! @Arguments M, N, matrices
DeclareOperation( "QuiverModuleHomomorphismNC",
                  [ IsQuiverModule, IsQuiverModule,
                    IsDenseList ] );
#! @EndGroup

#! @Description
#!  The representation homomorphism <A>f</A> considered as a module homomorphism
#!  over the algebra <A>A</A>.
#! @Arguments f, A
#! @Returns <Ref Filt="IsQuiverModuleHomomorphism"/>
DeclareOperation( "AsModuleHomomorphism",
                  [ IsQuiverRepresentationHomomorphism, IsQuiverAlgebra ] );

#! @Description
#!  The representation homomorphism <A>f</A> considered as a left module homomorphism.
#! @Arguments f, A
#! @Returns <Ref Filt="IsQuiverModuleHomomorphism"/>
DeclareAttribute( "AsLeftModuleHomomorphism",
                  IsQuiverRepresentationHomomorphism );

#! @Description
#!  The representation homomorphism <A>f</A> considered as a right module homomorphism.
#! @Arguments f, A
#! @Returns <Ref Filt="IsQuiverModuleHomomorphism"/>
DeclareAttribute( "AsRightModuleHomomorphism",
                  IsQuiverRepresentationHomomorphism );

#! @Description
#!  Given a module homomorphism <A>f</A> between modules <C>M</C> and <C>N</C>,
#!  returns the corresponding representation homomorphism between
#!  <C>UnderlyingRepresentation( M )</C> and <C>UnderlyingRepresentation( N )</C>.
#! @Arguments f
#! @Returns <Ref Filt="IsQuiverRepresentationHomomorphism"/>
DeclareAttribute( "UnderlyingRepresentationHomomorphism",
                  IsQuiverModuleHomomorphism );

#! @Description
#!  The matrices for the module homomorphism <A>f</A>.
#!  Returns a list of matrices, corresponding to each vertex in the quiver.
#! @Arguments f
#! @Returns list of <Ref Filt="IsQPAMatrix"/>
DeclareAttribute( "MatricesOfModuleHomomorphism",
                  IsQuiverModuleHomomorphism );
