tree grammar CSSTreeParser;

options {
	tokenVocab=CSSLexer;
	ASTLabelType=CommonTree;
}

@members {
	private org.slf4j.Logger log;

	private static final String MDC_KEY_URL = "css.url";
	private static final String MDC_KEY_LINE = "css.line";
	private static final String MDC_KEY_POSITION = "css.position";
    
	protected cz.vutbr.web.css.RuleFactory rf = cz.vutbr.web.css.CSSFactory.getRuleFactory();
	protected cz.vutbr.web.css.TermFactory tf = cz.vutbr.web.css.CSSFactory.getTermFactory();

	private enum MediaQueryState { START, TYPE, AND, EXPR, TYPEOREXPR }

    // block preparator
	protected cz.vutbr.web.csskit.antlr.Preparator preparator;
	private List<cz.vutbr.web.css.MediaQuery> wrapMedia;
	protected cz.vutbr.web.css.RuleList rules;
	private List<List<cz.vutbr.web.css.MediaQuery>> importMedia;
	private List<String> importPaths;
	private String defaultNamespace;
	private java.util.Map<String,String> namespaces;
	
	//prevent imports inside the style sheet
	private boolean preventImports;
	

  /**
   * Initializes the tree parser.
   * @param preparator The preparator to be used for creating the rules.
   * @param wrapMedia The media queries to be used for wrapping the created rules (e.g. in case
   *    of parsing and imported style sheet) or null when no wrapping is required.
   */
  public void init(cz.vutbr.web.csskit.antlr.Preparator preparator, List<cz.vutbr.web.css.MediaQuery> wrapMedia) {
		this.preparator = preparator;
		this.wrapMedia = wrapMedia;
		this.rules = null;
		this.importMedia = new ArrayList<List<cz.vutbr.web.css.MediaQuery>>();
		this.importPaths = new ArrayList<String>();
		this.preventImports = false;
		this.namespaces = new java.util.HashMap<String,String>();
		this.log = org.slf4j.LoggerFactory.getLogger(getClass());
	}   
  
  public cz.vutbr.web.css.RuleList getRules()
  {
    return rules;
  }
  
  public List<List<cz.vutbr.web.css.MediaQuery>> getImportMedia()
  {
    return importMedia;
  } 
  
  public List<String> getImportPaths()
  {
    return importPaths;
  }
  
  @Override
	public void emitErrorMessage(String msg) {
	    warn("ANTLR: {}", msg);
	}
		
	private String extractText(CommonTree token) {
        return token.getText();
    }
   
  private String extractTextUnescaped(CommonTree token) {
        return org.unbescape.css.CssEscape.unescapeCss(token.getText());
    }
   
  private java.net.URL extractBase(CommonTree token) {
      cz.vutbr.web.csskit.antlr.CSSToken ct = (cz.vutbr.web.csskit.antlr.CSSToken) token.getToken();
      return ct.getBase();
  }
    	
  private cz.vutbr.web.css.Declaration.Source extractSource(CommonTree token) {
      cz.vutbr.web.csskit.antlr.CSSToken ct = (cz.vutbr.web.csskit.antlr.CSSToken) token.getToken();
      cz.vutbr.web.css.Declaration.Source src = new cz.vutbr.web.css.Declaration.Source(ct.getBase(), ct.getLine(), ct.getCharPositionInLine());
      return src;
  }   
		
    private void logEnter(String entry) {
        trace("Entering '{}'", entry);
    }
    	
    private void logLeave(String leaving) {
	    trace("Leaving '{}'", leaving);
    }
    
    private CommonTree curToken = null;
    
    void error(String format, Object... args) {
        error(null, format, args);
    }
    
    void error(CommonTree token, String format, Object... args) {
        if (log.isErrorEnabled()) {
            if (token != curToken)
                mdcPutPosition(token);
            log.error(format, args);
        }
    }
    
    void warn(String format, Object... args) {
        warn(null, format, args);
    }
    
    void warn(CommonTree token, String format, Object... args) {
        if (log.isWarnEnabled()) {
            if (token != curToken)
                mdcPutPosition(token);
            log.warn(format, args);
        }
    }

    void info(String format, Object... args) {
        info(null, format, args);
    }
    
    void info(CommonTree token, String format, Object... args) {
        if (log.isInfoEnabled()) {
            if (token != curToken)
                mdcPutPosition(token);
            log.info(format, args);
        }
    }

    void debug(String format, Object... args) {
        debug(null, format, args);
    }
    
    void debug(CommonTree token, String format, Object... args) {
        if (log.isDebugEnabled()) {
            if (token != curToken)
                mdcPutPosition(token);
            log.debug(format, args);
        }
    }

    void trace(String format, Object... args) {
        trace(null, format, args);
    }
    
    void trace(CommonTree token, String format, Object... args) {
        if (log.isTraceEnabled()) {
            if (token != curToken)
                mdcPutPosition(token);
            log.trace(format, args);
        }
    }
    
    private void mdcPutPosition(CommonTree token) {
        if (token != null) {
            if (token.getToken() instanceof cz.vutbr.web.csskit.antlr.CSSToken) {
                cz.vutbr.web.csskit.antlr.CSSToken t = (cz.vutbr.web.csskit.antlr.CSSToken)token.getToken();
                mdcPutPosition(t.getBase(), t.getLine(), t.getCharPositionInLine());
            } else {
                mdcRemovePosition();
            }
        } else {
            mdcRemovePosition();
        }
        curToken = token;
    }
    
    private void mdcPutPosition(java.net.URL url, int line, int position) {
        org.slf4j.MDC.put(MDC_KEY_URL, ""+url);
        org.slf4j.MDC.put(MDC_KEY_LINE, ""+line);
        org.slf4j.MDC.put(MDC_KEY_POSITION, ""+position);
    }
    
    private void mdcRemovePosition() {
        org.slf4j.MDC.remove(MDC_KEY_URL);
        org.slf4j.MDC.remove(MDC_KEY_LINE);
        org.slf4j.MDC.remove(MDC_KEY_POSITION);
    }
}

inlinestyle returns [cz.vutbr.web.css.RuleList rules]
@init {
	logEnter("inlinestyle");
	$rules = this.rules = new cz.vutbr.web.csskit.RuleArrayList();
} 
@after {
	debug("\n***\n{}\n***\n", $rules);	   
	logLeave("inlinestyle");
}
	: 	^(INLINESTYLE decl=declarations) 
		{
			cz.vutbr.web.css.RuleBlock<?> rb = preparator.prepareInlineRuleSet(decl, null);
			if(rb!=null) {
			     $rules.add(rb);
			}
		} 
	|   ^(INLINESTYLE 
		 	(irs=inlineset {if(irs!=null) $rules.add(irs);} )+ )
	;


/**
 * Stylesheet, main rule
 */
stylesheet returns [cz.vutbr.web.css.RuleList rules]
@init {
	logEnter("stylesheet");
  $rules = this.rules = new cz.vutbr.web.csskit.RuleArrayList();
} 
@after {
	debug("\n***\n{}\n***\n", $rules);
	logLeave("stylesheet");
}
	: ^(STYLESHEET 
		 (s=statement { if(s!=null) $rules.add(s);})*  
	   )
	;

/**
 * Statement, main contents unit
 */	
statement returns [cz.vutbr.web.css.RuleBlock<?> stm]
scope {
    boolean invalid;
	
	// this flag allows us to encapsulate rulesets
	// into media when media import is used
	boolean insideAtstatement;	 
	
}
@init {
	logEnter("statement");
	$statement::invalid = false;
}   
@after {
  if ($statement::invalid)
      debug("Statement is invalid");
	logLeave("statement");
}
	: rs=ruleset {$stm=rs;} 
	| ats=atstatement {$stm=ats;}
	| INVALID_STATEMENT { $statement::invalid = true; }
	;
	

atstatement returns [cz.vutbr.web.css.RuleBlock<?> stmnt]
scope {
	cz.vutbr.web.css.RuleBlock<?> stm;
}
@init {
    logEnter("atstatement");
	$statement::insideAtstatement=true;
	$atstatement::stm = $stmnt = null;
	List<cz.vutbr.web.css.RuleSet> rules = null;
	List<cz.vutbr.web.css.RuleMargin> margins = null;
	String name = null;
	String pseudo = null;
}
@after {
    logLeave("atstatement");
}
	: CHARSET	// charset already set
	| INVALID_IMPORT // already handled
	| ^(IMPORT
	      (im=media)?
	      (iuri=import_uri)
	   )
	  {
	    if (!this.preventImports)
	    {
		    debug("Adding import: {}", iuri);
		    importMedia.add(im);
		    importPaths.add(iuri);
		  }
		  else 
        debug("Ignoring import: {}", iuri);
	  }
	| ^(n=NAMESPACE
	      (prf=namespace_prefix)?
	      (ns=namespace_uri)
	   )
	  {
	    if (prf == null) {
	      if (defaultNamespace != null)
	        warn(n, "Default namespace already declared");
	      debug(n, "Declaring default namespace: url({})", ns);
	      defaultNamespace = ns;
	    } else {
	      if (namespaces.containsKey(prf))
	        warn(n, "Namespace for prefix {} already declared", prf);
	      debug(n, "Declaring namespace: {} url({})", prf, ns);
	      namespaces.put(prf, ns);
	    }
	  }
  | ^(PAGE
      (i=IDENT
        { name = extractText(i); }
      )?
      (^(PSEUDOCLASS i=IDENT)
        { pseudo = extractText(i); }
      )?
      decl=declarations
      ^(SET (m=margin {
        if (m!=null) {
          if (margins == null) margins = new ArrayList<cz.vutbr.web.css.RuleMargin>();
          margins.add(m);
          debug("Inserted margin rule #{} into @page", margins.size()+1);
        }
      })*)
    )
    {
      $stmnt = preparator.prepareRulePage(decl, margins, name, pseudo);
      this.preventImports = true;
    }
  | ^(VIEWPORT decl=declarations)
    { $stmnt = preparator.prepareRuleViewport(decl); this.preventImports = true; }
  | ^(FONTFACE decl=declarations)
    { $stmnt = preparator.prepareRuleFontFace(decl); this.preventImports = true; }
	| ^(MEDIA (mediaList=media)? 
			(  rs=ruleset {
					   if(rules==null) rules = new ArrayList<cz.vutbr.web.css.RuleSet>();				
					   if(rs!=null) {
						   // this cast should be safe, because when inside of @statetement, oridinal ruleset
						   // is returned
					       rules.add((cz.vutbr.web.css.RuleSet)rs);
						   debug("Inserted ruleset ({}) into @media", rules.size());
					   }
					}
			  | INVALID_STATEMENT { debug("Skiping invalid statement in media"); }
			
			)*
	   )	
	   {
		   $stmnt = preparator.prepareRuleMedia(rules, mediaList);
		   this.preventImports = true;
	   }
	| unknown=unknown_atrule { $stmnt = unknown; }
	;

unknown_atrule returns [cz.vutbr.web.css.RuleBlock<?> stmnt]
@init { $stmnt = null; }
    : INVALID_ATSTATEMENT { debug("Skipping invalid at statement"); }
    ;

import_uri returns [String s]
  : (uri=URI) { s = extractText(uri); }
  | (str=STRING) { s = extractTextUnescaped(str); }
  ;

namespace_prefix returns [String prf]
  : (i=IDENT) { $prf = extractText(i); }
  ;

namespace_uri returns [String s]
  : (uri=URI) { $s = extractText(uri); }
  | (str=STRING) { $s = extractTextUnescaped(str); }
  ;

margin returns [cz.vutbr.web.css.RuleMargin m]
@init {
    logEnter("margin");
}
@after {
    logLeave("margin");
}
	: ^(area = MARGIN_AREA
		decl=declarations)
		{ $m = preparator.prepareRuleMargin(extractText(area).substring(1), decl); }
	;

media returns [List<cz.vutbr.web.css.MediaQuery> queries] 
@init {
   logEnter("media");
   $queries = new ArrayList<cz.vutbr.web.css.MediaQuery>();
}
@after {
   debug("Totally returned {} media queries.", $queries.size());							  
   logLeave("media");		   
}
	: (q = mediaquery {
				   $queries.add(q);
    } )+
	;

mediaquery returns [cz.vutbr.web.css.MediaQuery query]
scope {
    cz.vutbr.web.css.MediaQuery q;
    MediaQueryState state;
    boolean invalid;
}
@init {
    logEnter("mediaquery");
    $mediaquery::q = $query = rf.createMediaQuery();
    $query.unlock();
    $mediaquery::state = MediaQueryState.START;
    $mediaquery::invalid = false;
}
@after {
    if ($mediaquery::invalid)
    {
        trace("Skipping invalid rule {}", $query);
        $mediaquery::q.setType("all"); //change the malformed media queries to "not all"
        $mediaquery::q.setNegative(true);
    }
    logLeave("mediaquery");
}
  : ^(MEDIA_QUERY mediaterm+)
  ;

mediaterm
  : (i=IDENT {
            String m = extractText(i);
            MediaQueryState state = $mediaquery::state;
            if (m.equalsIgnoreCase("ONLY") && state == MediaQueryState.START)
            {
                $mediaquery::state = MediaQueryState.TYPEOREXPR;
            }
            else if (m.equalsIgnoreCase("NOT") && state == MediaQueryState.START)
            {
                $mediaquery::q.setNegative(true);
                $mediaquery::state = MediaQueryState.TYPEOREXPR;
            }
            else if (m.equalsIgnoreCase("AND") && state == MediaQueryState.AND)
            {
                $mediaquery::state = MediaQueryState.EXPR;
            }
            else if (state == MediaQueryState.START
                      || state == MediaQueryState.TYPE
                      || state == MediaQueryState.TYPEOREXPR)
            { 
                $mediaquery::q.setType(m);
                $mediaquery::state = MediaQueryState.AND;
            }
            else
            {
                trace("Invalid media query: found ident: {} state: {}", m, state);
                $mediaquery::invalid = true;
            }
        }
      )
   | (e=mediaexpression {
            if ($mediaquery::state == MediaQueryState.START 
                || $mediaquery::state == MediaQueryState.EXPR
                || $mediaquery::state == MediaQueryState.TYPEOREXPR)
            {
                if (e.getFeature() != null) //the expression is valid
                {
		                $mediaquery::q.add(e); 
		                $mediaquery::state = MediaQueryState.AND;
		            }
		            else
		            {
		                trace("Invalidating media query for invalud expression");
		                $mediaquery::invalid = true;
		            }
            }
            else
            {
                trace("Invalid media query: found expr, state: {}", $mediaquery::state);
                $mediaquery::invalid = true;
            }
      })
   | (INVALID_STATEMENT {
            $mediaquery::invalid = true;
      })
   ;

mediaexpression returns [cz.vutbr.web.css.MediaExpression expr]
@init {
    logEnter("mediaquery");
    $expr = rf.createMediaExpression();
}
@after {
    logLeave("mediaquery");
}
    : d=declaration { 
          if (d != null) { //if the declaration is valid
              $expr.setFeature(d.getProperty()); 
              $expr.replaceAll(d);
          } 
      }
    ;

inlineset returns [cz.vutbr.web.css.RuleBlock<?> is]
@init {
     logEnter("inlineset");
	 List<cz.vutbr.web.css.Selector.PseudoPage> pplist = new ArrayList<cz.vutbr.web.css.Selector.PseudoPage>();
}
@after {
     logLeave("inlineset");   
}
	: ^(RULE (p=pseudo {pplist.add(p);})* decl=declarations)
	  	{ $is = preparator.prepareInlineRuleSet(decl, pplist); }
	;
    
    
/**
 * The most common block in CSS file,
 * set of declarations with selector
 */  
ruleset returns [cz.vutbr.web.css.RuleBlock<?> stmnt]
@init {
    logEnter("ruleset"); 
    List<cz.vutbr.web.css.CombinedSelector> cslist = new ArrayList<cz.vutbr.web.css.CombinedSelector>();
}
@after {
    if($statement::invalid) {
        $stmnt = null;
        debug("Ruleset not valid, so not created");
    }
    else {    
		 $stmnt = preparator.prepareRuleSet(cslist, decl, (this.wrapMedia != null && !this.wrapMedia.isEmpty()), this.wrapMedia);
		 this.preventImports = true; 
        }		
    logLeave("ruleset");
}    
    : ^(RULE 
        (cs=combined_selector  
        {if(cs!=null && !cs.isEmpty() && !$statement::invalid) {
            cslist.add(cs);
            debug("Inserted combined selector ({}) into ruleset",  cslist.size());
         }   
        } )*
		decl=declarations 
    )
    ;  

/**
 * Multiple CSS declarations
 */ 
declarations returns [List<cz.vutbr.web.css.Declaration> decl]
@init {
		  logEnter("declarations");
		  $decl = new ArrayList<cz.vutbr.web.css.Declaration>();
}
@after {
		   logLeave("declarations");
}
	: ^(SET (d=declaration {
	     if(d!=null) {
            $decl.add(d);
            debug("Inserted declaration #{} ", $decl.size()+1);
		 }	
	 })*
	 )
	;


/**
 * CSS declaration
 */
declaration returns [cz.vutbr.web.css.Declaration decl]
scope {
    cz.vutbr.web.css.Declaration d;
    boolean invalid;
} 
@init {
    logEnter("declaration");
    $declaration::d = $decl = rf.createDeclaration();
    $declaration::invalid = false;
} 
@after {
    if($declaration::invalid || $declaration.isEmpty()) {
        $decl=null;
        debug("Declaration was invalidated or already invalid");
    }
    else {
        debug("Returning declaration: {}.", $decl);
    }
    logLeave("declaration");    
}
  : ^(DECLARATION 
	    (important { $decl.setImportant(true); debug("IMPORTANT"); })?
      (INVALID_DIRECTIVE { $declaration::invalid=true; })?
      property 
      t=terms {$decl.replaceAll(t);}      
     )
	| INVALID_DECLARATION { $declaration::invalid=true;}
  ;

important
    : IMPORTANT
    ;   

/**
 * Setting property of declaration
 */  
property
@init {
    logEnter("property");
}
@after {
	debug("Setting property: {}", $declaration::d.getProperty());	   
    logLeave("property");
}    
  : i = IDENT { $declaration::d.setProperty(extractText(i)); $declaration::d.setSource(extractSource(i)); }
  | MINUS i = IDENT { $declaration::d.setProperty("-" + extractText(i)); $declaration::d.setSource(extractSource(i)); }
  ;

/**
 * Term of CSSDeclaration
 */
terms returns [List<cz.vutbr.web.css.Term<?>> tlist]
scope {
    List<cz.vutbr.web.css.Term<?>> list;
    cz.vutbr.web.css.Term<?> term;
    cz.vutbr.web.css.Term.Operator op;
    int unary;
    boolean dash;
}   
@init {
    logEnter("terms");
    $terms::list = $tlist = new ArrayList<cz.vutbr.web.css.Term<?>>();
    $terms::term = null;
    $terms::op = null;
    $terms::unary = 1;
    $terms::dash = false;
}    
@after {
	debug("Totally added {} terms", $tlist.size());	   
    logLeave("terms");
}
    : ^(VALUE term+)
    ;
    
term
@init {
  logEnter("term");
}
    : valuepart 
      {// set operator, store and create next 
       if(!$declaration::invalid && $terms::term!=null) {
          $terms::term.setOperator($terms::op);
          $terms::list.add($terms::term);
          // reinitialization
          $terms::op = cz.vutbr.web.css.Term.Operator.SPACE;
          $terms::unary = 1;
          $terms::dash = false;
          $terms::term = null;
       }    
      }
    | CURLYBLOCK { $declaration::invalid = true;}
    | ATKEYWORD { $declaration::invalid = true;}
    ;   

valuepart
@after{
    // convert color
    cz.vutbr.web.css.Term<?> term = $terms::term;
    if(term!=null) {
        cz.vutbr.web.css.TermColor colorTerm = null;
        if(term instanceof cz.vutbr.web.css.TermIdent) {
            colorTerm = tf.createColor((cz.vutbr.web.css.TermIdent)term);
            if (colorTerm != null)
                term = colorTerm;
        }
        else if(term instanceof cz.vutbr.web.css.TermFunction) {
            colorTerm = tf.createColor((cz.vutbr.web.css.TermFunction)term);
            if(colorTerm != null)
                term = colorTerm;
        }
        // replace with color
        if(colorTerm!=null) {
            $terms::term = colorTerm;
        }                    
    }
}
    : (MINUS {$terms::dash=true;})? i=IDENT   {$terms::term = tf.createIdent(extractText(i), $terms::dash);}
    | CLASSKEYWORD {$declaration::invalid = true;}
	  | (MINUS {$terms::unary=-1;})? n=NUMBER    {$terms::term = tf.createNumeric(extractText(n), $terms::unary);}
    | (MINUS {$terms::unary=-1;})? p=PERCENTAGE  { $terms::term = tf.createPercent(extractText(p), $terms::unary);}
    | (MINUS {$terms::unary=-1;})? d=DIMENSION   
			{String dim = extractText(d);
				 $terms::term = tf.createDimension(dim, $terms::unary);
			     if($terms::term==null) {
					 info("Unable to create dimension from {}, unary {}", dim, $terms::unary);
			         $declaration::invalid = true;
				 }
	    }
    | s=string    
			{ if(s!=null) $terms::term = tf.createString(s);
			  else $declaration::invalid=true;
			}
    | u=URI       {$terms::term = tf.createURI(extractText(u), extractBase(u));}
    | h=HASH    
	    {$terms::term = tf.createColor(extractText(h));
	     if($terms::term==null)
	         $declaration::invalid = true;
	    }
    | UNIRANGE  {$declaration::invalid = true;}
    | INCLUDES  {$declaration::invalid = true;}
    | COLON     {$declaration::invalid = true;}
    | COMMA     {$terms::op = cz.vutbr.web.css.Term.Operator.COMMA;}    
    | GREATER   {$declaration::invalid = true;}
    | LESS      {$declaration::invalid = true;}
    | QUESTION  {$declaration::invalid = true;}
    | PERCENT   {$declaration::invalid = true;}
    | EQUALS    {$declaration::invalid = true;}
    | SLASH     {$terms::op = cz.vutbr.web.css.Term.Operator.SLASH;}
		| PLUS		  {$declaration::invalid = true;}
		| ASTERISK  {$declaration::invalid = true;}
		| e=EXPRESSION {
		    String exprval = extractText(e);
        cz.vutbr.web.css.TermExpression expr = tf.createExpression(exprval.substring(11,exprval.length()-1)); //strip the 'expression()'
        $terms::term = expr;
		}
    | (MINUS {$terms::unary=-1;})? ^(f=FUNCTION t=terms?) {
        // create function
        cz.vutbr.web.css.TermFunction function = tf.createFunction();
        function.setFunctionName(extractText(f));
        if ($terms::unary == -1) //if started with minus, add the minus to the function name
            function.setFunctionName('-' + function.getFunctionName());
        if (t != null)
        	function.setValue(t);
        $terms::term = function;
    }
    | DASHMATCH {$declaration::invalid = true;}
    | ^(PARENBLOCK any*) {$declaration::invalid = true;}
    | ^(BRACEBLOCK any*) {$declaration::invalid = true;}    
  ;
  
/**
 * Construction of selector
 */
combined_selector returns [cz.vutbr.web.css.CombinedSelector combinedSelector]
@init {
	logEnter("combined_selector");	  
	$combinedSelector = (cz.vutbr.web.css.CombinedSelector) rf.createCombinedSelector().unlock();
    boolean invalid = false;
}
@after {  
    // entire ruleset is not valid when selector is not valid
    // there is no need to parse selector's when already marked as invalid
    if($statement::invalid || invalid) {
        $combinedSelector = null;
        if($statement::invalid) { 
			debug("Ommiting combined selector, whole statement discarded");
		}	
        else { 
			debug("Combined selector is invalid");               
        }
		// mark whole ruleset as invalid
        $statement::invalid = true;
    }
    else {
        debug("Returing combined selector: {}.", $combinedSelector); 
    }
    logLeave("combined_selector"); 
}    
	: s=selector {
	     if (s != null)
	         $combinedSelector.add(s);
	     else
	         invalid = true;
	  }
	 (c=combinator s=selector {
	     if (s != null) {
	         s.setCombinator(c);
	         $combinedSelector.add(s);
	     } else
	         invalid = true;
	  }
	 )*
	;

combinator returns [cz.vutbr.web.css.Selector.Combinator combinator]
@init{ logEnter("combinator"); }
@after{ logLeave("combinator"); }
	: CHILD {$combinator=cz.vutbr.web.css.Selector.Combinator.CHILD;}
	| ADJACENT {$combinator=cz.vutbr.web.css.Selector.Combinator.ADJACENT;}
  | PRECEDING {$combinator=cz.vutbr.web.css.Selector.Combinator.PRECEDING;}
	| DESCENDANT {$combinator=cz.vutbr.web.css.Selector.Combinator.DESCENDANT;}
	;


selector returns [cz.vutbr.web.css.Selector sel]
scope {
	cz.vutbr.web.css.Selector s;
}
@init {
	logEnter("selector");
	$sel = (cz.vutbr.web.css.Selector)rf.createSelector().unlock();
	String name = null;
	String ns = null;
	String prf = null;
}
@after {
	logLeave("selector");
}
    : ^(SELECTOR
        ^(ELEMENT
           (
            ^(PREFIX (
               p=namespace_prefix { prf = p; }
               |
               ASTERISK { prf = cz.vutbr.web.css.Selector.ElementName.WILDCARD; }
             )?) {
               if (prf == null) prf = "";
             }
           )?
           (
             i=IDENT { name = extractText(i); }
             |
             ASTERISK { name = cz.vutbr.web.css.Selector.ElementName.WILDCARD; }
           )
         ) {
             if (prf == null) {
                 if (defaultNamespace != null)
                     ns = defaultNamespace;
                 else
                     ns = null;
             } else if (prf.equals("")) {
                 ns = "";
             } else if (prf.equals(cz.vutbr.web.css.Selector.ElementName.WILDCARD)) {
                 ns = null;
             } else if (namespaces.containsKey(prf)) {
                 ns = namespaces.get(prf);
             } else {
                 error("No namespace declared for prefix {}", prf);
                 $sel = null;
             }
             if ($sel != null) {
                 cz.vutbr.web.css.Selector.ElementName en = rf.createElement(ns, name, prf);
                 debug("Adding element name: {}.", en);
                 $sel.add(en.lock());
             }
         }
         (sp=selpart {
             if (sp == null)
                 $sel = null;
             else if ($sel != null)
                 $sel.add(sp);
         })*
       )
    | ^(SELECTOR
         (sp=selpart {
             if (sp == null)
                 $sel = null;
             else if ($sel != null)
                 $sel.add(sp);
         })+
       )
    | INVALID_SELECTOR { $sel = null; }
  ;

selpart returns [cz.vutbr.web.css.Selector.SelectorPart part]
@init {
	logEnter("selpart");
}
@after {
    logLeave("selpart");
}
    : h=HASH { $part = rf.createID(extractText(h)); }
    | c=CLASSKEYWORD { $part = rf.createClass(extractText(c)); }
    | ^(ATTRIBUTE ea=attribute { $part = ea;} )
    | p=pseudo { $part = p; }
    | INVALID_SELPART
    ;
 
attribute returns [cz.vutbr.web.css.Selector.ElementAttribute elemAttr]
@init {
    logEnter("attribute");
    String name = null;
    String ns = null;
    String prf = null;
	String value = null;
	cz.vutbr.web.css.Selector.Operator op = cz.vutbr.web.css.Selector.Operator.NO_OPERATOR;
	boolean isStringValue = false;
	boolean invalid = false;
}
@after{
    if (prf == null || prf.equals(""))
        ns = "";
    else if (prf.equals(cz.vutbr.web.css.Selector.ElementAttribute.WILDCARD))
        ns = null;
    else if (namespaces.containsKey(prf))
        ns = namespaces.get(prf);
    else {
        error("No namespace declared for prefix {}", prf);
        invalid = true;
    }
    if (!invalid) {
        $elemAttr = rf.createAttribute(value, isStringValue, op, ns, name, prf);
    }
    logLeave("attribute");
}

	: (
	   ^(PREFIX (
	      p=namespace_prefix { prf = p; }
	      |
	      ASTERISK { prf = cz.vutbr.web.css.Selector.ElementAttribute.WILDCARD; }
	    )?) {
	      if (prf == null) prf = "";
	    }
	  )?
	  i=IDENT {name=extractText(i); }
	  ((EQUALS {op=cz.vutbr.web.css.Selector.Operator.EQUALS; } 
	   | INCLUDES {op=cz.vutbr.web.css.Selector.Operator.INCLUDES; } 
	   | DASHMATCH {op=cz.vutbr.web.css.Selector.Operator.DASHMATCH; }
     | CONTAINS {op=cz.vutbr.web.css.Selector.Operator.CONTAINS; }
     | STARTSWITH {op=cz.vutbr.web.css.Selector.Operator.STARTSWITH; }
     | ENDSWITH {op=cz.vutbr.web.css.Selector.Operator.ENDSWITH; }
	   ) 
	   (i=IDENT {
		value=extractText(i);
		isStringValue=false;
		}
	   | s=string {
		 if(s!=null)  { 
			value=s;
			isStringValue=true;
		 } else {
		    invalid = true;
		 }
		}
	   ))?
	; 
	
pseudo returns [cz.vutbr.web.css.Selector.PseudoPage pseudoPage]
@init {
		logEnter("pseudo");
}
  /* pseudo classes */
	: ^(PSEUDOCLASS i=IDENT)
		{
			try {
				$pseudoPage = rf.createPseudoClass(extractText(i));
			} catch (Exception e1) {
				// maybe a single colon was used for a pseudo element
				try {
					$pseudoPage = rf.createPseudoElement(extractText(i)); }
				catch (Exception e2) {
					error(i, "invalid pseudo declaration: " + extractText(i));
                    $pseudoPage = null;
				}
			}
		}
	| ^(PSEUDOCLASS f=FUNCTION i=IDENT)
		{
			$pseudoPage = rf.createPseudoClassFunction(extractText(f), extractText(i));
		}
	| ^(PSEUDOCLASS f=FUNCTION m=MINUS? n=NUMBER)
		{
      String exp = extractText(n);
      if (m != null) exp = "-" + exp;
			$pseudoPage = rf.createPseudoClassFunction(extractText(f), exp);
		}
  | ^(PSEUDOCLASS f=FUNCTION m=MINUS? n=INDEX)
    {
      String exp = extractText(n);
      if (m != null) exp = "-" + exp;
      $pseudoPage = rf.createPseudoClassFunction(extractText(f), exp);
    }
  /* pseudo elements */
  | ^(PSEUDOELEM i=IDENT)
    {
      try {
          $pseudoPage = rf.createPseudoElement(extractText(i));
      } catch (Exception e) {
          error(i, "invalid pseudo declaration: " + extractText(i));
          $pseudoPage = null;
      }
    }
  | ^(PSEUDOELEM f=FUNCTION i=IDENT)
    {
      try {
          $pseudoPage = rf.createPseudoElementFunction(extractText(f), extractText(i));
      } catch (Exception e) {
          error(f, "invalid pseudo declaration", e);
      }
    }
  | ^(PSEUDOELEM f=FUNCTION m=MINUS? n=NUMBER)
    {
      String exp = extractText(n);
      if (m != null) exp = "-" + exp;
      try {
          $pseudoPage = rf.createPseudoElementFunction(extractText(f), exp);
      } catch (Exception e) {
          error(f, "invalid pseudo declaration", e);
      }
    }
  | ^(PSEUDOELEM f=FUNCTION m=MINUS? n=INDEX)
    {
      String exp = extractText(n);
      if (m != null) exp = "-" + exp;
      try {
          $pseudoPage = rf.createPseudoElementFunction(extractText(f), exp);
      } catch (Exception e) {
          error(f, "invalid pseudo declaration", e);
      }
    }
	;

string returns [String s]
	: st=STRING { $s=extractTextUnescaped(st);}
	| INVALID_STRING {$s=null;}
	;
  
any
  : IDENT
  | CLASSKEYWORD
  | NUMBER
  | PERCENTAGE
  | DIMENSION
  | string
  | URI
  | HASH
  | UNIRANGE
  | INCLUDES
  | COLON
  | COMMA
  | GREATER
  | EQUALS
  | SLASH
  | EXCLAMATION
  | ^(FUNCTION any*) 
  | DASHMATCH
  | ^(PARENBLOCK any*)
  | ^(BRACEBLOCK any*)
  ;
