''
'' UGL addon - DC bouding box and pixel perfect collision
''
''
declare function ugluBBCollision% ( byval DCA as long, _
                                    byval xa as integer, _
                                    byval ya as integer, _
                                    byval DCB as long, _
                                    byval xb as integer, _
                                    byval yb as integer )
                                    
declare function ugluPPCollision& ( byval DCA as long, _
                                    byval xa as integer, _
                                    byval ya as integer, _
                                    byval DCB as long, _
                                    byval xb as integer, _
                                    byval yb as integer )
                                    
declare function ugluPPCollisionEx& ( byval DCA as long, _
                                    byval xa as integer, _
                                    byval ya as integer, _
                                    byval DCB as long, _
                                    byval xb as integer, _
                                    byval yb as integer, _
                                    byval col as long )