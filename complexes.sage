############################################################
#
# The homotopy category of projective complexes in sage
#
############################################################
class ProjectiveComplex(object):
    '''The class of ProjectiveComplexes over a ring (not necessarily
    commutative). A projective complex is a complex of projective objects. 
    '''
    def __init__(self, basering, objects = {}, maps = {}, names={}):
        '''
        Arguments -
        basering: Base ring (not necessarily commutative)

        objects: A dictionary of type {i: [P]} where i is an integer and P is projective module over the base ring. The internal details of P are never used, so it may as well be a blob. But in all constructions, it will be used as if it were a projective module.

        maps: A dictionary of type {i: {(a,b): r}} where i is an integer, (a,b) is a pair of positive integers, and r is an element of basering. The key i represents the map from the i-th to (i+1)-th place of the complex. The pair (a,b) says that the map is from the a-th object in the list of objects at the i-th place to the b-th object in the list of objects at the (i+1)-th place. The value r says that the map is given by right multiplication by r. Currently, there is no provision to specify more complicated maps. 

        names: A dictionary of type {P: n} where P is a projective module and n is a string that acts as a short name for P to put in the string representation of the complex.
        '''
        self._objects = objects.copy()
        self._maps = maps.copy()
        self._names = names.copy()
        self._basering = basering
        if len(objects.keys()) > 0:
            self._minIndex = min(objects.keys())
            self._maxIndex = max(objects.keys())
        else:
            self._minIndex = 0
            self._maxIndex = 0

        if not self.checkComplexity():
            print("Warning: This is not a chain complex!")

    def __str__(self):
        ks = self._objects.keys()
        if len(ks) == 0:
            smallest,largest = 0,0
        else:
            smallest,largest = min(ks),max(ks)
        s = "[" + str(smallest) + "]: "

        for i in range(smallest,largest + 1):
            objects = self._objects.get(i,[])
            if len(objects) == 0:
                s = s + "0"
            else:
                s = s + "+".join([self._names[x] if x in self._names else str(x) for x in objects])
            if i < largest:
                s = s + " → "
        return s

    def __repr__(self):
        return str(self)

    def basering(self):
        return self._basering

    def minIndex(self):
        '''
        An integer n such that self.objects(m) = [] for m < n.
        '''
        return self._minIndex

    def maxIndex(self):
        '''
        An integer n such that self.objects(m) = [] for m > n.
        '''
        return self._maxIndex

    def objects(self, i):
        '''
        A list of projective objects whose direct sum forms the i-th component of self.
        '''
        return list(self._objects.get(i, []))

    def maps(self, i):
        '''
        The map from the i-th to the (i+1)-th component, represented as a dictionary {(a,b): r}. The map corresponds to (right) multiplication by the matrix associated to this dictionary.
        '''
        return self._maps.get(i, {}).copy()

    def names(self):
        '''
        Short, readable names for the projective objects in the complex.
        '''
        return self._names.copy()

    def shift(self, n = 1):
        '''
        A new complex obtained by homologically shifting self by [n].
        '''
        def shiftDict(d, n):
            return {x-n: d[x] for x in d.keys()}
        return ProjectiveComplex(self._basering,
                                 {x-n: self._objects[x] for x in self._objects.keys()},
                                 {x-n: {k: (-1)^n * self._maps[x][k] for k in self._maps[x].keys()}
                                  for x in self._maps.keys()},
                                 self._names)

    def copy(self):
        return ProjectiveComplex(self._basering, self._objects, self._maps, self._names)

    def addObject(self, place, obj, name = None):
        '''
        Add object `obj` at place `place` with name `name`. It goes as the last entry of the list of objects at place `place`.
        '''
        if place not in self._objects:
            self._objects[place] = []
        self._objects[place].append(obj)

        if place not in self._maps:
            self._maps[place] = {}

        if name != None:
            self._names[obj] = name

        self._minIndex = min(place, self._minIndex)
        self._maxIndex = max(place, self._maxIndex)
        
    def cleanUp(self):
        '''
        Remove spurious matrix entries (zeros) and spurious object lists (empty lists).
        '''
        # Remove maps
        for i in self._maps.keys():
            for k in self._maps[i].keys():
                if self._maps[i][k] == 0:
                    self._maps[i].pop(k)
        # Remove objects
        for i in self._objects.keys():
            if self._objects[i] == []:
                self._objects.pop(i)

        if len(self._objects.keys()) > 0:
            self._minIndex = min(self._objects.keys())
            self._maxIndex = max(self._objects.keys())
        else:
            self._minIndex = 0
            self._maxIndex = 0

    def minimize(self):
        '''
        Apply minimizeAt(i) for all i.
        '''
        for i in range(self.minIndex(), self.maxIndex()):
            self.minimizeAt(i)
        

    def addMap(self, place, i, j, scalar):
        '''
        Add a map from the i-th object at place to the j-th object at place+1 given by right multiplication by scalar.
        '''
        # All actions are right actions!
        if i < 0 or i >= len(self.objects(place)):
            raise IndexError("Index out of bounds")
        if j < 0 or j >= len(self.objects(place+1)):
            raise IndexError("Index out of bounds")
        
        if place not in self._maps:
            self._maps[place] = {}
        self._maps[place][(i,j)] = self._basering(scalar)

    def checkComplexity(self):
        '''
        Check that this forms a chain complex.
        '''
        matrices = {}
        for i in range(self.minIndex(), self.maxIndex()):
            sourceDim = len(self._objects.get(i, []))
            targetDim = len(self._objects.get(i+1, []))
            matrices[i] = matrix(sourceDim, targetDim, self._maps.get(i, {}))

        for i in range(self.minIndex(), self.maxIndex()-1):
            if matrices[i] * matrices[i+1] != 0:
                print "Differential squared not zero at " + str(i) + "."
                return False

        return True

    def directSum(self, Q):
        '''
        Direct sum of this complex and the complex Q
        '''
        # By convention, the objects of Q go after the objects of self, in order.
        objs, maps = {}, {}
        names = self.names()
        names.update(Q.names())
        smallest = min([self.minIndex(),Q.minIndex()])
        largest = max([self.maxIndex(),Q.maxIndex()])

        for i in range(smallest, largest + 1):
            objs[i] = self.objects(i) + Q.objects(i)
            
        for k in range(smallest, largest):
            maps[k] = self.maps(k)
            l,w = len(self.objects(k)), len(self.objects(k+1))
            for (p,q) in Q.maps(k):
                maps[k][(p+l,q+w)] = Q.maps(k)[(p,q)]
        return ProjectiveComplex(self._basering, objs, maps, names)
                      
    def minimizeAt(self, place):
        '''
        Factor out a complex (presumably the biggest such) that is chain homotopic to zero and is concentrated in degrees place and place+1.
        '''
        k = self._basering.base_ring()
        
        # Find an object at i and an object at (i+1) with an isomorphism between them.
        def _findIso(place):
            def invertible(alpha):
                try:
                    return alpha.is_unit()
                except NotImplementedError:
                    try:
                        return alpha.is_invertible()
                    except Exception(e):
                        raise e
            
            for i in range(0, len(self.objects(place))):
                for j in range(0, len(self.objects(place+1))):
                    fij = self.maps(place).get((i,j), self._basering(0))
                    if invertible(fij):
                        return i,j, fij
            return None, None, None

        alreadyMinimized = False
        while not alreadyMinimized:
            source, target, alpha = _findIso(place)
            if source == None or target == None or alpha == None:
                print("Nothing left to minimize at " + str(place))
                alreadyMinimized = True
                continue

            # Change the maps from place to place+1

            def invert(alpha):
                try:
                    return 1/alpha
                except TypeError:
                    try:
                        return alpha.inverse()
                    except AttributeError(e):
                        raise e
            
            newMapsPlace = {}
            for i in range(0, len(self.objects(place))):
                for j in range(0, len(self.objects(place+1))):
                    if (i,j) == (source, target):
                        changeij = 0
                    else:
                        changeij = self.maps(place).get((i,target), 0) * invert(alpha) * self.maps(place).get((source,j), 0)
                    newMapsPlace[(i,j)] = self.maps(place).get((i,j), 0) - changeij


            # The maps from place-1 to place and place+1 to place+2 do not need to be changed substantially, apart from the indexing.
            # Now we update the maps
            for i in range(0, len(self.objects(place))):
                for j in range(0, len(self.objects(place+1))):
                    self._maps[place][(i,j)] = newMapsPlace[(i,j)]

            # At this point, our complex is a direct sum of F (source) -> F (target) and another complex
            # We simply drop the source and the target
            self._objects[place].pop(source)
            self._objects[place+1].pop(target)

            # and re-index as needed
            matrixAtPlace = matrix(len(self.objects(place))+1, len(self.objects(place+1))+1, self.maps(place))
            newMatrixAtPlace = matrixAtPlace.delete_rows([source]).delete_columns([target])
            self._maps[place] = newMatrixAtPlace.dict()

            matrixAtPlaceMinus1 = matrix(len(self.objects(place-1)), len(self.objects(place))+1, self.maps(place-1))
            if matrixAtPlaceMinus1.ncols() > 0:
                newMatrixAtPlaceMinus1 = matrixAtPlaceMinus1.delete_columns([source])
                self._maps[place-1] = newMatrixAtPlaceMinus1.dict()

            matrixAtPlacePlus1 = matrix(len(self.objects(place+1))+1, len(self.objects(place+2)) ,self.maps(place+1))
            if matrixAtPlacePlus1.nrows() > 0:
                newMatrixAtPlacePlus1 = matrixAtPlacePlus1.delete_rows([target])
                self._maps[place+1] = newMatrixAtPlacePlus1.dict()

        #Finally we do a cleanup
        self.cleanUp()
        return 

def cone(P, Q, M):
    '''
    The cone of M: P -> Q. M must define a map of chain complexes from P to Q.
    '''
    if not checkMap(P, Q, M):
        raise TypeError("Not a chain map. Cannot make a cone.")
    
    D = P.directSum(Q.shift(-1))
    for place in M.keys():
        for (i,j) in M[place]:
            D.addMap(place, i, j+len(P.objects(place+1)), M[place][(i,j)])

    return D
    

def checkMap(P, Q, M):
    '''
    Check that M defines a map of chain complexes from P to Q.
    M must have the type {i: d} where i is an integer and d is a dictionary {(a,b): r} whose associated matrix defines the map from P to Q (by right multiplication).
    '''
    minIndex = min(P.minIndex(), Q.minIndex())
    maxIndex = max(P.maxIndex(), Q.maxIndex())
    for i in range(minIndex, maxIndex):
        dPi = matrix(P.maps(i))
        dQi = matrix(Q.maps(i))
        Mi = matrix(len(Q.objects(i)), len(P.objects(i)), M[i])
        Mip1 = matrix(len(Q.objects(i+1)), len(P.objects(i+1)), M[i+1])
        if dPi * Mip1 != Mi * dQi:
            return False
    return True
    
    
