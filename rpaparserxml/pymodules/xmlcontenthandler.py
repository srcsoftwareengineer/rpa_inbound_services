# !/usr/bin/python3
# -*- encoding: utf-8 -*-

'''
Created on 1 de set de 2021
@module: rpaparserxml.pymodules.xmlcontenthandler
@summary:
@author: Sandro Regis Cardoso | Software Engineer
@contact: src.softwareengineer@gmail.com
'''
from xml.sax.handler import ContentHandler


class XmlContentHandler(ContentHandler):
    '''
    classdocs
    '''

    def __init__(self, params):
        '''
        Constructor
        '''
